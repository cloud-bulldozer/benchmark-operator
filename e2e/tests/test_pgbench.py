from pytest import mark
from models.test_base import TestBase, default_timeout


@mark.pgbench
class TestPgBench(TestBase):
    workload = "pgbench"
    indices = ["ripsaw-pgbench-summary", "ripsaw-pgbench-raw"]

    def setup_method(self, method):
        super().setup_method(method)
        cluster = self.helpers.get_cluster()
        cluster.wait_for_pods_by_app("postgres", "my-ripsaw")
        postgres_pod = cluster.get_pods_by_app("postgres", "my-ripsaw").items[0]
        postgres_pod_ip = postgres_pod.status.pod_ip
        run = self._item.callspec.getparam('run')
        run.update_spec("spec/workload/args/databases[0]/host", postgres_pod_ip)
        

    
    def test_pgbench(self, run):
        self.run_and_check_benchmark(run, desired_running_state="Run Workload")