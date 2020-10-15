import unittest
import pytest




@pytest.mark.usefixtures("helpers")
class TestBase():
    workload = ""
    def setup_method(self, method):
        run = self._item.callspec.getparam('run')
        run.cleanup()

    def teardown_method(self, method): 
        run = self._item.callspec.getparam('run')
        run.cleanup()

    def run_and_check_benchmark(self, run):
        run.start()
        results = run.wait()
        assert results['status'] == "Complete"