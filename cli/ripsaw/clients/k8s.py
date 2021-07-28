from kubernetes import client, config, watch, utils
import json
import time
import yaml
from ripsaw.util.exceptions import BenchmarkFailedError, BenchmarkTimeoutError
from ripsaw.util import logging

logger = logging.get_logger(__name__)

class Cluster:
    def __init__(self):
        config.load_kube_config()
        self.api_client = client.ApiClient()
        self.core_client = client.CoreV1Api()
        self.batch_client = client.BatchV1Api()
        self.crd_client = client.CustomObjectsApi()

    # Get Functions
    def get_pods_by_app(self, app, namespace):
        label_selector = f"app={app}"
        return self.core_client.list_namespaced_pod(namespace, label_selector=label_selector, watch=False)

    def get_pod_logs_by_app(self, app, namespace, container):
        pods = self.get_pods_by_app(app, namespace).items
        return [ self.core_client.read_namespaced_pod_log(name=pod.metadata.name, namespace=namespace, container=container) for pod in pods ]

    def get_jobs_by_app(self, app, namespace):
        label_selector = f"app={app}"
        return self.batch_client.list_namespaced_job(namespace, label_selector=label_selector, watch=False)
    
    def get_pods_by_label(self, label_selector, namespace):
        return self.core_client.list_namespaced_pod(namespace, label_selector=label_selector, watch=False)

    def get_pod_logs_by_label(self, label_selector, namespace, container):
        pods = self.get_pods_by_label(label_selector, namespace).items
        return [ self.core_client.read_namespaced_pod_log(name=pod.metadata.name, namespace=namespace, container=container) for pod in pods ]

    def get_nodes(self, label_selector):
        return self.core_client.list_node(label_selector=label_selector)

    def get_node_names(self, label_selector):
        return [node.metadata.name for node in self.get_nodes(label_selector).items]

    def get_namespaces_with_label(self, label_key, label_value):
        label_selector = f"{label_key}={label_value}"
        return self.core_client.list_namespace(label_selector=label_selector)

    def get_benchmark(self, name, namespace):
        return self.crd_client.get_namespaced_custom_object(
            group="ripsaw.cloudbulldozer.io",
            version="v1alpha1",
            namespace=namespace,
            plural="benchmarks",
            name=name
        )

    def get_benchmark_metadata(self, benchmark_name, benchmark_namespace):
        benchmark = self.get_benchmark(benchmark_name, benchmark_namespace)
        return {
            'name': benchmark['metadata']['name'],
            'namespace': benchmark['metadata']['namespace'],
            'uuid': benchmark['status'].get('uuid', "Not Assigned Yet"),
            'suuid': benchmark['status'].get('suuid', "Not Assigned Yet"),
            'related_job': f"{benchmark['spec']['workload']['name']}-{benchmark['status']['suuid']}",
            'status': benchmark['status'].get('state', "")
        }

    # Waiters
    def wait_for_pods_by_label(self, label_selector, namespace, timeout=300):
        waiting_for_pods = True
        timeout_interval = 0
        while waiting_for_pods:
            if timeout_interval >= timeout:
                raise TimeoutError()
            time.sleep(3)
            pods = self.get_pods_by_label(label_selector, namespace).items
            if len(pods) == 0 and timeout_interval < 60:
                continue
            elif len(pods) == 0:
                raise PodsNotFoundError(f"Found no pods with label selector {label_selector}")
            else:
                [logger.info(
                    f"{pod.metadata.namespace}\t{pod.metadata.name}\t{pod.status.phase}") for pod in pods]
                waiting_for_pods = (
                    any([pod.status.phase != "Running" for pod in pods]))

    def wait_for_benchmark(self, name, namespace, desired_state="Completed", timeout=300):
        waiting_for_benchmark = True
        logger.info(f"Waiting for state: {desired_state}")
        timeout_interval = 0
        logger.info(
                f"BENCHMARK\tUUID\t\t\t\t\tSTATE")
        while waiting_for_benchmark:
            if timeout_interval >= timeout:
                raise BenchmarkTimeoutError(name)
            benchmark = self.get_benchmark(name, namespace)
            bench_status = benchmark.get('status', {})
            uuid = bench_status.get('uuid', "Not Assigned Yet")
            current_state = bench_status.get('state', "")
            logger.info(
                f"{benchmark['metadata']['name']}\t{uuid}\t{current_state}")
            if current_state == "Failed":
                raise BenchmarkFailedError(
                    benchmark['metadata']['name'], benchmark['status']['uuid'])

            waiting_for_benchmark = (current_state != desired_state)
            time.sleep(3)

            timeout_interval += 3
        logger.info(
            f"{benchmark['metadata']['name']} with uuid {uuid} has reached the desired state {desired_state}")

    # Create Functions

    def create_benchmark_async(self, benchmark):
        self.crd_client.create_namespaced_custom_object(
            group="ripsaw.cloudbulldozer.io",
            version="v1alpha1",
            namespace=benchmark['metadata']['namespace'],
            plural="benchmarks",
            body=benchmark
        )

    def create_benchmark(self, benchmark, desired_state="Running", timeout=300):
        self.crd_client.create_namespaced_custom_object(
            group="ripsaw.cloudbulldozer.io",
            version="v1alpha1",
            namespace=benchmark['metadata']['namespace'],
            plural="benchmarks",
            body=benchmark
        )

        try:
            self.wait_for_benchmark(
                benchmark['metadata']['name'], benchmark['metadata']['namespace'], desired_state=desired_state, timeout=timeout)
        except BenchmarkFailedError:
            logger.error("error, benchmark failed")
        else:
            return self.get_benchmark_metadata(benchmark['metadata']['name'], benchmark['metadata']['namespace'])

    def create_from_yaml(self, yaml_file):
        return utils.create_from_yaml(self.api_client, yaml_file)

    # Delete Functions

    def delete_benchmark(self, name, namespace):
        logger.info(f"Deleting benchmark {name} in namespace {namespace}")
        self.crd_client.delete_namespaced_custom_object(
            group="ripsaw.cloudbulldozer.io",
            version="v1alpha1",
            namespace=namespace,
            plural="benchmarks",
            name=name
        )
        logger.info(f"Deleted benchmark {name} in namespace {namespace}")

    def delete_all_benchmarks(self, namespace):
        all_benchmarks = self.crd_client.list_namespaced_custom_object(
            group="ripsaw.cloudbulldozer.io",
            version="v1alpha1",
            namespace=namespace,
            plural="benchmarks"
        )

        [self.delete_benchmark(benchmark['metadata']['name'], namespace)
         for benchmark in all_benchmarks.get('items', [])]

    def delete_namespace(self, namespace):
        return self.core_client.delete_namespace(namespace, client.V1DeleteOptions())

    def delete_namespaces_with_label(self, label_key, label_value):
        [self.core_client.delete_namespace(
            namespace.metadata.name) for namespace in self.get_namespaces_with_label(label_key, label_value).items]
    
    # Patch Functions
    def patch_node(self, node, patch):
        return self.core_client.patch_node(node, patch)
