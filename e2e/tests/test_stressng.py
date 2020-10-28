from pytest import mark
from models.test_base import TestBase, default_timeout


@mark.stressng
class TestStressng(TestBase):
    workload = "stressng"
    indices = ["ripsaw-stressng-results"]

    @mark.timeout(default_timeout)
    def test_stressng(self, run):
        self.run_and_check_benchmark(run, desired_running_state="Benchmark running")