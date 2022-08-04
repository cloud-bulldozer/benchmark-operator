#!/usr/bin/env python
# -*- coding: utf-8 -*-
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

"""Create portable definition of a Kubernetes/Openshift Cluster"""


import time
import urllib3

from kubernetes import client, config
from ripsaw.util import logging
from ripsaw.util.exceptions import BenchmarkFailedError, BenchmarkTimeoutError, PodsNotFoundError
import os

logger = logging.get_logger(__name__)

# how many seconds to sleep before looping back in wait commands
DEFAULT_WAIT_TIME = 1


class Cluster:
    """
    Class definition of a Kubernetes/Openshift Cluster

    Attributes:
        api_client (ApiClient)
        core_client (CoreV1Api)
        batch_client (BatchV1Api)
        crd_client (CustomObjectsApi)
    """

    def __init__(self, kubeconfig_path=None):
        """Initialize object and create clients from specified kubeconfig"""
        client_config = client.Configuration()
        http_proxy = os.getenv('http_proxy', None)
        """Proxy has auth header"""
        if http_proxy and "@" in http_proxy:
            proxy_auth = http_proxy.split("@")[0].split("//")[1]
        proxy_url = http_proxy
        if proxy_url:
            client_config.proxy = proxy_url
            if proxy_auth:
                client_config.proxy_headers = urllib3.make_headers(proxy_basic_auth=proxy_auth)
        config.load_kube_config(config_file=kubeconfig_path, client_configuration=client_config)
        self.api_client = client.ApiClient(client_config)
        self.core_client = client.CoreV1Api(self.api_client)
        self.batch_client = client.BatchV1Api(self.api_client)
        self.crd_client = client.CustomObjectsApi(self.api_client)

    def get_pods(self, label_selector, namespace):
        """Get pods matching specified label selector in specified namespace"""
        return self.core_client.list_namespaced_pod(namespace, label_selector=label_selector, watch=False)

    def get_pod_logs(self, label_selector, namespace, container):
        """Get container logs from pods with labels in namespace"""
        pods = self.get_pods(label_selector, namespace).items
        return [
            self.core_client.read_namespaced_pod_log(
                name=pod.metadata.name, namespace=namespace, container=container
            )
            for pod in pods
        ]

    def get_jobs(self, label_selector, namespace):
        """Get jobs with specified labels in namespace"""
        return self.batch_client.list_namespaced_job(namespace, label_selector=label_selector, watch=False)

    def get_nodes(self, label_selector=None):
        """Get all nodes with label selector, default is to get all nodes"""
        return self.core_client.list_node(label_selector=label_selector)

    def get_node_names(self, label_selector=None):
        """Get names of all nodes with label selector"""
        return [node.metadata.name for node in self.get_nodes(label_selector).items]

    def get_namespaces(self, label_selector=None):
        """Get namespaces with labels"""
        return self.core_client.list_namespace(label_selector=label_selector)

    def get_benchmark(self, name, namespace="benchmark-operator"):
        """Get benchmark resource"""
        return self.crd_client.get_namespaced_custom_object(
            group="ripsaw.cloudbulldozer.io",
            version="v1alpha1",
            namespace=namespace,
            plural="benchmarks",
            name=name,
        )

    def get_benchmark_metadata(self, name, namespace="benchmark-operator"):
        """Get benchmark metadata from the cluster resource"""
        benchmark = self.get_benchmark(name, namespace)
        return {
            "name": benchmark["metadata"]["name"],
            "namespace": benchmark["metadata"]["namespace"],
            "uuid": benchmark.get("status", {}).get("uuid", "Not Assigned Yet"),
            "suuid": benchmark.get("status", {}).get("suuid", "Not Assigned Yet"),
            "status": benchmark.get("status", {}).get("state", ""),
        }

    # Waiters
    def wait_for_pods(self, label_selector, namespace, timeout=300):
        """wait for pods with label in namespace for specified timeout"""
        waiting_for_pods = True
        timeout_interval = 0
        while waiting_for_pods:
            if timeout_interval >= timeout:
                raise TimeoutError()
            pods = self.get_pods(label_selector, namespace).items
            if len(pods) == 0 and timeout_interval < 60:
                continue

            if len(pods) == 0 and timeout_interval > 60:
                raise PodsNotFoundError(f"Found no pods with label selector {label_selector}")

            _ = [
                logger.info(f"{pod.metadata.namespace}\t{pod.metadata.name}\t{pod.status.phase}")
                for pod in pods
            ]
            waiting_for_pods = any(pod.status.phase != "Running" for pod in pods)

            time.sleep(DEFAULT_WAIT_TIME)
            timeout_interval += DEFAULT_WAIT_TIME

    def wait_for_benchmark(
        self, name, namespace="benchmark-operator", desired_state="Completed", timeout=300
    ):
        """Wait for benchmark to hit desired state for specified timeout"""
        waiting_for_benchmark = True
        logger.info(f"Waiting for state: {desired_state}")
        timeout_interval = 0
        logger.info("BENCHMARK\tUUID\t\t\t\t\tSTATE")
        while waiting_for_benchmark:
            if timeout_interval >= timeout:
                raise BenchmarkTimeoutError(name)
            benchmark = self.get_benchmark(name, namespace)
            bench_status = benchmark.get("status", {})
            uuid = bench_status.get("uuid", "Not Assigned Yet")
            current_state = bench_status.get("state", "")
            logger.info(f"{benchmark['metadata']['name']}\t{uuid}\t{current_state}")
            if current_state == "Failed":
                raise BenchmarkFailedError(benchmark["metadata"]["name"], benchmark["status"]["uuid"])

            waiting_for_benchmark = current_state != desired_state
            time.sleep(DEFAULT_WAIT_TIME)

            timeout_interval += DEFAULT_WAIT_TIME
        logger.info(
            f"{benchmark['metadata']['name']} with uuid {uuid} has reached the desired state {desired_state}"
        )

    # Create Functions

    def create_benchmark(self, benchmark):
        """Create benchmark in the cluster"""
        self.crd_client.create_namespaced_custom_object(
            group="ripsaw.cloudbulldozer.io",
            version="v1alpha1",
            namespace=benchmark["metadata"]["namespace"],
            plural="benchmarks",
            body=benchmark,
        )

    # Delete Functions

    def delete_benchmark(self, name, namespace="benchmark-operator"):
        """Delete the benchmark from the cluster"""
        logger.info(f"Deleting benchmark {name} in namespace {namespace}")
        self.crd_client.delete_namespaced_custom_object(
            group="ripsaw.cloudbulldozer.io",
            version="v1alpha1",
            namespace=namespace,
            plural="benchmarks",
            name=name,
        )
        logger.info(f"Deleted benchmark {name} in namespace {namespace}")

    def delete_all_benchmarks(self, namespace="benchmark-operator"):
        """Delete all the benchmarks from the cluster"""
        all_benchmarks = self.crd_client.list_namespaced_custom_object(
            group="ripsaw.cloudbulldozer.io", version="v1alpha1", namespace=namespace, plural="benchmarks"
        )

        _ = [
            self.delete_benchmark(benchmark["metadata"]["name"], namespace)
            for benchmark in all_benchmarks.get("items", [])
        ]

    def delete_namespace(self, namespace):
        """Delete namespace from the cluster"""
        return self.core_client.delete_namespace(namespace)

    def delete_namespaces_with_label(self, label_selector):
        """Delete all namespaces with label from the cluster."""
        return [
            self.core_client.delete_namespace(namespace.metadata.name)
            for namespace in self.get_namespaces(label_selector=label_selector).items
        ]
