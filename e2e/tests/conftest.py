import pytest 
import os
from util.k8s import Cluster
from models.workload import Workload 
import logging


# Test Arguments

def pytest_addoption(parser):
    parser.addoption("--es-server", action="store", default=None, help="elasticsearch address")
    parser.addoption("--prom-token", action="store", default=None, help="prometheus token")
    

@pytest.fixture(scope="class")
def overrides(request, metadata_collection_overrides, prometheus_token):
    request.cls.overrides = {}
    request.cls.metadata_collection_enabled = request.cls.overrides["spec.metadata.collection"] = metadata_collection_overrides["metadata_collection_enabled"]

    if request.cls.metadata_collection_enabled:
        request.cls.es_server = request.cls.overrides["spec.elasticsearch.server"] = metadata_collection_overrides["es_server"]
        if prometheus_token is not None and request.cls.benchmark_needs_prometheus:
            request.cls.overrides['spec.prometheus.es_server'] = f"http://{metadata_collection_overrides['es_server']}"
            request.cls.overrides['spec.prometheus.prom_token'] = prometheus_token

@pytest.fixture(scope="session")
def metadata_collection_overrides(request):
    metadata_collection_enabled = (request.config.getoption("--es-server") is not None)
    es_server= request.config.getoption("--es-server")
    

    if metadata_collection_enabled:
        return {
            "metadata_collection_enabled": metadata_collection_enabled, 
            "es_server": es_server,
        }
    else: 
        return {
            "metadata_collection_enabled": metadata_collection_enabled
        }

@pytest.fixture(scope="session")
def prometheus_token(request):
    return request.config.getoption("--prom-token")

class Helpers:
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
        run_metadata = item.funcargs.get("run").metadata
        header = "-----Benchmark Metadata-----"
        metadata_string=f"{run_metadata['name']}\t{run_metadata['uuid']}\t{run_metadata['status']}"
        full_log = f"\n{header}\n{metadata_string}\n"
        logging.info(full_log)
    elif rep.when == "call" and rep.failed:
        logging.error(Cluster().get_pod_logs_by_label("name=benchmark-operator", "my-ripsaw"))




# Test Generator
def pytest_generate_tests(metafunc):
    if "run" in metafunc.fixturenames and metafunc.cls.workload is not None:
        workload = Helpers.get_workload(metafunc.cls.workload)
        runs = workload.benchmark_runs
        ids = [ run.name for run in runs ]
        metafunc.parametrize("run", runs, ids=ids)


