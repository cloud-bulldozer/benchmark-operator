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

import kubernetes
import pytest
from ripsaw.util.exceptions import BenchmarkTimeoutError
import pytest 

@pytest.mark.unit
class TestCluster():
    def test_get_pods(self, cluster):
        label_selector = "component=etcd"
        pods = cluster.get_pods(label_selector=label_selector, namespace="kube-system")
        assert len(pods.items) == 1
        assert "etcd-pytest-kind-control-plane" in pods.items[0].metadata.name

    def test_get_pod_logs(self, cluster):
        label_selector = "component=etcd"
        logs = cluster.get_pod_logs(label_selector=label_selector, namespace="kube-system", container="etcd")
        assert len(logs) > 0

    def test_get_jobs(self, cluster, test_job): 
        label_selector = "app=test-job"
        jobs = cluster.get_jobs(label_selector=label_selector, namespace="default")
        assert len(jobs.items) == 1
        assert jobs.items[0].metadata.name == "busybox"

    def test_get_nodes(self, cluster):
        nodes = cluster.get_nodes()
        assert len(nodes.items) == 1


    def test_get_node_names(self, cluster):
        names = cluster.get_node_names()
        assert len(names) == 1
        assert type(names[0]) is str
        assert names[0] == 'pytest-kind-control-plane'
    
    def test_get_namespaces(self, cluster):
        namespaces = cluster.get_namespaces()
        names = [namespace.metadata.name for namespace in namespaces.items ]
        assert "kube-system" in names

    def test_get_benchmark(self, cluster, test_benchmark):
        benchmark = cluster.get_benchmark(name="byowl")
        assert benchmark['metadata']['name'] == 'byowl'

    def test_get_benchmark_metadata(self, cluster, test_benchmark):
        benchmark_metadata = cluster.get_benchmark_metadata(name="byowl")
        assert benchmark_metadata == {
            "name": "byowl",
            "namespace": "benchmark-operator",
            "uuid": "Not Assigned Yet",
            "suuid": "Not Assigned Yet",
            "status": ""
        }

    def test_wait_for_pods(self, cluster, test_job):
        label_selector = "job-name=busybox"
        namespace = "default"
        cluster.wait_for_pods(label_selector, namespace)
        pods = cluster.get_pods(label_selector, namespace)
        assert len(pods.items) == 1
        assert pods.items[0].status.phase == "Running"
        

    def test_create_benchmark_async(self, cluster, test_benchmark_model):
        name = test_benchmark_model.name
        namespace = test_benchmark_model.namespace
        cluster.create_benchmark(test_benchmark_model.yaml)
        assert name == cluster.get_benchmark(name, namespace)['metadata']['name']


    def test_wait_for_benchmark_timeout(self, cluster, test_benchmark):
        name = "byowl"
        namespace = "benchmark-operator"
        with pytest.raises(BenchmarkTimeoutError) as e_info:
            cluster.wait_for_benchmark(name, namespace, timeout=5)

    def test_delete_benchmark(self, cluster, test_benchmark):
        name = "byowl"
        namespace = "benchmark-operator"
        cluster.delete_benchmark(name, namespace)
        with pytest.raises(kubernetes.client.exceptions.ApiException) as e_info:
            cluster.get_benchmark(name,namespace)
        
    
    def test_delete_all_benchmarks(self, cluster, test_benchmark):
        name = "byowl"
        namespace = "benchmark-operator"
        cluster.delete_all_benchmarks(namespace)
        with pytest.raises(kubernetes.client.exceptions.ApiException) as e_info:
            cluster.get_benchmark(name,namespace)

    def test_delete_namespace(self, cluster, test_namespace):
        expected_name = test_namespace[0]
        label_selector = test_namespace[1]
        namespace = cluster.get_namespaces(label_selector=label_selector).items[0]
        assert namespace.metadata.name == expected_name
        response = cluster.delete_namespace(namespace.metadata.name)
        assert response.status == "{'phase': 'Terminating'}"
    
    def test_delete_namespaces_with_label(self, cluster, test_multiple_namespaces):
        expected_namespaces = test_multiple_namespaces[0]
        label_selector = test_multiple_namespaces[1]
        namespaces = cluster.get_namespaces(label_selector=label_selector).items
        responses = cluster.delete_namespaces_with_label(label_selector=label_selector)
        assert expected_namespaces == [namespace.metadata.name for namespace in namespaces]
        assert len(responses) == len(namespaces)
        assert all([response.status == "{'phase': 'Terminating'}" for response in responses])