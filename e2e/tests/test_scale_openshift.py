from pytest import mark
from models.test_base import TestBase, default_timeout


@mark.scale
class TestScale(TestBase):
    workload = "scale"
    indices = ["openshift-cluster-timings"]

    @mark.timeout(default_timeout)
    def test_scale(self, run):
        self.run_and_check_benchmark(run)