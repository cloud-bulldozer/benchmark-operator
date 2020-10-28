from pytest import mark
from models.test_base import TestBase, default_timeout

default_timeout = 100000

@mark.kube_burner
class TestKubeBurner(TestBase):
    workload = "kube-burner"
    indices = ["ripsaw-kube-burner"]
    benchmark_needs_prometheus = True

    def delete_namespaces_for_run(self, run):
        job = run.yaml["spec"]["workload"]["args"]["workload"]
        self.helpers.get_cluster().delete_namespaces_with_label("kube-burner-job", job)

    def setup_method(self, method):
        super().setup_method(method)
        self.delete_namespaces_for_run(self._item.callspec.getparam('run'))
        pass

    def teardown_method(self, method):
        self.delete_namespaces_for_run(self._item.callspec.getparam('run'))
        super().teardown_method(method)
        pass
    
    def test_kube_burner(self, run):
        self.run_and_check_benchmark(run)