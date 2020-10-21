from pytest import mark
from models.test_base import TestBase, default_timeout


@mark.ycsb
class TestYcsb(TestBase):
    workload = "ycsb"
    indices = ["ripsaw-ycsb-summary", "ripsaw-ycsb-results"]

    @mark.timeout(default_timeout)
    def test_ycsb(self, run):
        self.run_and_check_benchmark(run)