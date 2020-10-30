from pytest import mark
from models.test_base import TestBase, default_timeout


@mark.servicemesh
class TestServiceMesh(TestBase):
    workload = "servicemesh"
    indices = ["ripsaw-servicemesh-summary", "ripsaw-servicemesh-raw"]

    # @pytest.mark.skip(reason="flaky")
    def test_servicemesh(self, run):
        self.run_and_check_benchmark(run)