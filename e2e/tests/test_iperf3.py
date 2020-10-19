from pytest import mark
from models.test_base import TestBase, default_timeout


@mark.iperf3
class TestIPerf3(TestBase):
    workload = "iperf3"

    @mark.timeout(default_timeout)
    def test_iperf3(self, run):
        self.run_and_check_benchmark(run)