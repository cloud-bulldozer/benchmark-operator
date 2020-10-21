from pytest import mark
from models.test_base import TestBase, default_timeout


@mark.smallfile
class TestSmallFile(TestBase):
    workload = "smallfile"
    indices = ["ripsaw-smallfile-results", "ripsaw-smallfile-rsptimes"]

    @mark.timeout(default_timeout)
    def test_smallfile(self, run):
        self.run_and_check_benchmark(run)