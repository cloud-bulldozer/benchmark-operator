from pytest import mark
from models.test_base import TestBase, default_timeout

default_timeout = 100000

@mark.kube_burner
class TestKubeBurner(TestBase):
    workload = "kube-burner"
    indices = ["ripsaw-kube-burner"]
    benchmark_needs_prometheus = True

    
    def test_kube_burner(self, run):
        self.run_and_check_benchmark(run)