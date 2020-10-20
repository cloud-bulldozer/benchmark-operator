from pytest import mark
from models.test_base import TestBase, default_timeout


@mark.byowl
class TestByowl(TestBase):
    workload = "byowl"
    metadata_collection_enabled = False
    check_es = False
    inject_cli_args = False

    @mark.timeout(default_timeout)
    def test_byowl(self, run):
        self.run_and_check_benchmark(run)