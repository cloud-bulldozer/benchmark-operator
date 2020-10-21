from pytest import mark
from models.test_base import TestBase, default_timeout


@mark.kube_burner
class TestKubeBurner(TestBase):
    workload = "kube-burner"
    indices = ["ripsaw-kube-burner"]

    @mark.timeout(default_timeout)
    def test_kube_burner(self, run):
        self.run_and_check_benchmark(run)