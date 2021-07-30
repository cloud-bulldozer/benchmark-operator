import pytest
import pytest_kind
import time
from ripsaw.clients.k8s import Cluster

@pytest.fixture(scope="session")
def cluster(kind_cluster):
    time.sleep(15)
    return Cluster(kubeconfig_path=str(kind_cluster.kubeconfig_path.resolve()))


@pytest.fixture(scope="function")
def test_job(kind_cluster):
    yield kind_cluster.kubectl("apply", "-f", "tests/resources/job.yaml")
    kind_cluster.kubectl("delete", "-f", "tests/resources/job.yaml")

@pytest.fixture(scope="session")
def benchmark_crd(kind_cluster):
    yield kind_cluster.kubectl("apply", "-f", "../config/crd/bases/ripsaw.cloudbulldozer.io_benchmarks.yaml")
    kind_cluster.kubectl("delete", "-f", "../config/crd/bases/ripsaw.cloudbulldozer.io_benchmarks.yaml")

@pytest.fixture(scope="session")
def benchmark_namespace(kind_cluster):
    yield kind_cluster.kubectl("create", "namespace", "benchmark-operator")
    kind_cluster.kubectl("delete", "namespace", "benchmark-operator", "--ignore-not-found")

@pytest.fixture(scope="function")
def test_benchmark(kind_cluster, benchmark_crd, benchmark_namespace):
    yield kind_cluster.kubectl("apply", "-f", "tests/resources/benchmark.yaml")
    kind_cluster.kubectl("delete", "-f", "tests/resources/benchmark.yaml")


@pytest.fixture(scope="function")
def test_namespace(kind_cluster):
    name = "test-namespace"
    label = "test=true"
    kind_cluster.kubectl("create", "namespace", name)
    kind_cluster.kubectl("label", "namespaces", name, label)
    yield name, label
    kind_cluster.kubectl("delete", "namespace", name, "--ignore-not-found")


@pytest.fixture(scope="function")
def test_multiple_namespaces(kind_cluster): 
    name = "test-namespace"
    label = "multi-namespace=true"
    namespaces = f"{name}-1 {name}-2 {name}-3".split(" ")
    [kind_cluster.kubectl("create", "namespace", namespace) for namespace in namespaces]
    [kind_cluster.kubectl("label", "namespaces", namespace, label) for namespace in namespaces]
    yield namespaces, label
    [kind_cluster.kubectl("delete", "namespace", namespace, "--ignore-not-found") for namespace in namespaces]


