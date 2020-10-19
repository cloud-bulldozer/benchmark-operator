import unittest
from pytest import mark
import os
import subprocess

default_timeout = 6000

@mark.usefixtures("helpers")
class TestBase():
    workload = ""

    def setup_method(self, method):
        self.create_test_resources()
        run = self._item.callspec.getparam('run')
        run.cleanup()

    def teardown_method(self, method):
        self.delete_test_resources() 
        run = self._item.callspec.getparam('run')
        run.cleanup()

    @classmethod
    def create_test_resources(cls):
        cls._apply_test_resources("apply")
    
    @classmethod
    def delete_test_resources(cls):
        cls._apply_test_resources("delete")
    

    @classmethod
    def _apply_test_resources(cls, operation):
        test_dir = os.path.join(cls.helpers.get_benchmark_dir(), cls.workload, "resources")
        if (os.path.isdir(test_dir)):
            for entry in os.scandir(test_dir):
                if (entry.path.endswith(".yaml")):
                    subprocess.run([
                        "kubectl",
                        operation,
                        "-f",
                        entry.path
                    ], capture_output=True)

    def run_and_check_benchmark(self, run, status="Complete"):
        run.start()
        results = run.wait(desired_state = status)
        assert results['status'] == status