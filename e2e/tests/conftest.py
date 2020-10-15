import pytest 
import os
from e2e.util.k8s import Cluster
from e2e.models.workload import Workload 

class Helpers:
    def __init__(self):
        self.cluster = Cluster()

    @staticmethod
    def all_runs_passed(runs):
         return all(run.get('status', "") == "Complete" for run in runs)  

    @staticmethod
    def get_benchmark_dir():
        benchmark_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(__file__))), "benchmarks")
        print(benchmark_dir)
        return benchmark_dir
    
    @staticmethod
    def get_cluster():
        return Cluster()
    
    @staticmethod 
    def get_workload(name):
        return Workload(name, Cluster(), Helpers.get_benchmark_dir())



@pytest.fixture(scope="class")
def helpers(request):
    request.cls.helpers = Helpers()

def pytest_generate_tests(metafunc):
    if "run" in metafunc.fixturenames and metafunc.cls.workload is not None:
        workload = Helpers.get_workload(metafunc.cls.workload)
        runs = workload.benchmark_runs
        metafunc.parametrize("run", runs)

@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_protocol(item, nextitem):
    item.cls._item = item
    yield


