class TestCluster():
    def test_get_pods(self, cluster):
        label_selector = "component=etcd"
        pods = cluster.get_pods(label_selector=label_selector, namespace="kube-system")
        assert len(pods.items) == 1
        assert "etcd-pytest-kind-control-plane" in pods.items[0].metadata.name

    def test_get_pod_logs(self, cluster):
        label_selector = "component=etcd"
        logs = cluster.get_pod_logs(label_selector=label_selector, namespace="kube-system", container="etcd")
        assert "/health OK" in logs[0]

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

    # def test_wait_for_pods_by_label(self):
    #     assert 0

    # def test_wait_for_benchmark(self):
    #     assert 0

    # def test_create_benchmark_async(self):
    #     assert 0

    # def test_create_benchmark(self):
    #     assert 0

    # def test_delete_benchmark(self):
    #     assert 0
    
    # def test_delete_all_benchmarks(self):
    #     assert 0

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