from pytest import mark
from models.test_base import TestBase, default_timeout

@mark.hammerdb
class TestHammerDB(TestBase):
    workload = "hammerdb"

    def setup_method(self, method):
        super().setup_method(method)
        self.helpers.get_cluster().wait_for_pods_by_app("mssql", "sql-server")


    
    def test_hammerdb(self, run):
        self.run_and_check_benchmark(run, desired_running_state="DB workload running", desired_complete_state="DB Workload Complete")