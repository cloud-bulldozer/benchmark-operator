from pytest import mark
from models.test_base import TestBase, default_timeout


@mark.servicemesh
class TestServiceMesh(TestBase):
    workload = "servicemesh"
    indices = ["ripsaw-servicemesh-summary", "ripsaw-servicemesh-raw"]

    @mark.timeout(default_timeout)
    def test_servicemesh(self, run):
        self.run_and_check_benchmark(run)