from pytest import mark
from models.test_base import TestBase, default_timeout


@mark.sysbench
class TestSysbench(TestBase):
    workload = "sysbench"
    inject_cli_args = False

    @mark.timeout(default_timeout)
    def test_sysbench(self, run):
        self.run_and_check_benchmark(run)