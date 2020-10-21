from pytest import mark
from models.test_base import TestBase, default_timeout


@mark.vegeta
class TestVegeta(TestBase):
    workload = "vegeta"
    indices = ["ripsaw-vegeta-results"]

    @mark.timeout(default_timeout)
    def test_vegeta(self, run):
        self.run_and_check_benchmark(run)