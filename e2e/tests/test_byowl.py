import pytest 


from e2e.util.k8s import Cluster
from e2e.models.workload import Workload 

def test_byowl(helpers):
    byowl_workload = Workload("byowl", Cluster(), helpers.get_benchmark_dir())
    runs = byowl_workload.run_all()
    assert helpers.all_runs_passed(runs) == True
