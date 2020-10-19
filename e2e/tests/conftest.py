import pytest 
import os
from util.k8s import Cluster
from models.workload import Workload 


# Test Arguments

def pytest_addoption(parser):
    parser.addoption("--es-server", action="store", default=None, help="elasticsearch address")
    parser.addoption("--es-port", action="store", default=None, help="elasticsearch address")
    parser.addoption("--prom-token", action="store", default=None, help="prometheus token")
    

# Test Helpers 
class Helpers:
    def __init__(self):
        self.cluster = Cluster()

    @staticmethod
    def all_runs_passed(runs):
         return all(run.get('status', "") == "Complete" for run in runs)  

    @staticmethod
    def get_benchmark_dir():
        benchmark_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(__file__))), "benchmarks")
        return benchmark_dir
    
    @staticmethod
    def get_cluster():
        return Cluster()
    
    @staticmethod 
    def get_workload(name):
        return Workload(name, Helpers.get_cluster(), Helpers.get_benchmark_dir())

    @staticmethod
    def create_test_resources(name):
        test_dir = os.path.join(Helpers.get_benchmark_dir(), name, "resources")
        if (os.path.isdir(test_dir)):
            for entry in os.scandir(test_dir):
                if (entry.path.endswith(".yaml")):
                    Helpers.get_cluster().create_from_yaml(entry.path)





@pytest.fixture(scope="class")
def helpers(request):
    request.cls.helpers = Helpers()

def pytest_generate_tests(metafunc):
    if "run" in metafunc.fixturenames and metafunc.cls.workload is not None:
        workload = Helpers.get_workload(metafunc.cls.workload)
        runs = workload.benchmark_runs
        metafunc.parametrize("run", runs)


# Hooks

@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_protocol(item, nextitem):
    item.cls._item = item
    yield

@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    rep = outcome.get_result()

    if rep.when == "call" and not rep.failed:
        print(item.funcargs.get("run", {}).metadata)