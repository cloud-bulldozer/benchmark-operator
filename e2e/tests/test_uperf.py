from pytest import mark
from models.test_base import TestBase, default_timeout


@mark.uperf
class TestUperf(TestBase):
    workload = "uperf"
    indices = ["ripsaw-uperf-results"]

    @mark.timeout(default_timeout)
    def test_uperf(self, run):
        self.run_and_check_benchmark(run)