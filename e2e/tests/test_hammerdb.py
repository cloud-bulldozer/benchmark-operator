from pytest import mark
from models.test_base import TestBase, default_timeout

@mark.hammerdb
class TestHammerDB(TestBase):
    workload = "hammerdb"

    def setup_method(self, method):
        super().setup_method(method)
        self.helpers.get_cluster().wait_for_pods_by_app("mssql", "sql-server")


    @mark.timeout(default_timeout)
    def test_hammerdb(self, run):
        self.run_and_check_benchmark(run, status="DB Workload Complete")