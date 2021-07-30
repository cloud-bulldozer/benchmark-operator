import pytest
import pytest_kind
from ripsaw.clients.k8s import Cluster

@pytest.fixture(scope="session")
def cluster(kind_cluster):
    return Cluster(kubeconfig_path=str(kind_cluster.kubeconfig_path.resolve()))


