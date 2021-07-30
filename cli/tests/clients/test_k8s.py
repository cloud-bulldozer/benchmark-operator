class TestCluster():
    def test_get_pods_by_app(self, cluster):
        pass 

    # def test_get_pods_logs_by_app(self):
    #     assert 0

    # def test_get_jobs_by_app(self):
    #     assert 0

    # def test_get_pods_by_label(self):
    #     assert 0

    # def test_get_pod_logs_by_label(self):
    #     assert 0

    def test_get_nodes(self, cluster):
        nodes = cluster.get_nodes()
        assert len(nodes.items) == 1


    def test_get_node_names(self, cluster):
        names = cluster.get_node_names()
        assert len(names) == 1
        assert type(names[0]) is str
        assert names[0] == 'pytest-kind-control-plane'
    
    # def test_get_namespaces_with_label(self):
    #     assert 0

    # def test_get_benchmark(self):
    #     assert 0

    # def test_get_benchmark_metadata(self):
    #     assert 0

    # def test_wait_for_pods_by_label(self):
    #     assert 0

    # def test_wait_for_benchmark(self):
    #     assert 0

    # def test_create_benchmark_async(self):
    #     assert 0

    # def test_create_benchmark(self):
    #     assert 0

    # def test_create_from_yaml(self):
    #     assert 0

    # def test_delete_benchmark(self):
    #     assert 0
    
    # def test_delete_all_benchmarks(self):
    #     assert 0

    # def test_delete_namespace(self):
    #     assert 0
    
    # def test_delete_namespaces_with_label(self):
    #     assert 0

    # def test_patch_node(self):
    #     assert 0
        