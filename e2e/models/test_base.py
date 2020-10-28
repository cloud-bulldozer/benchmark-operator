import unittest
import elasticsearch
from pytest import mark
import os
import logging
import subprocess
from flaky import flaky
from time import sleep
from util.exceptions import BenchmarkFailedError, BenchmarkTimeoutError

default_timeout = 600
default_retries = 3

@mark.usefixtures("helpers", "overrides")
@flaky(max_runs=default_retries)
class TestBase():
    workload = ""
    indices = ""
    inject_cli_args = True
    check_es = True
    benchmark_needs_prometheus = False

    def setup_method(self, method):
        self.create_test_resources()
        run = self._item.callspec.getparam('run')
        self.inject_overrides(run)
        run.cleanup()

    def teardown_method(self, method):
        self.delete_test_resources() 
        run = self._item.callspec.getparam('run')
        run.cleanup()

    @classmethod
    def inject_overrides(cls, run):
        if cls.inject_cli_args:
            [run.update_spec(key, value) for key, value in cls.overrides.items()]

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
                    print(subprocess.run([
                        "kubectl",
                        operation,
                        "-f",
                        entry.path
                    ], capture_output=True))
    @classmethod
    def _check_es(cls, uuid, index, es_ssl):
        

        _es_connection_string = str(cls.es_server)

        if es_ssl == "true":
            import urllib3
            urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
            ssl_ctx = ssl.create_default_context()
            ssl_ctx.check_hostname = False
            ssl_ctx.verify_mode = ssl.CERT_NONE
            es = elasticsearch.Elasticsearch([_es_connection_string], send_get_body_as='POST',
                                                    ssl_context=ssl_ctx, use_ssl=True)
        else:
            es = elasticsearch.Elasticsearch([_es_connection_string], send_get_body_as='POST')
        es.indices.refresh(index=index)
        results = es.search(index=index, body={'query': {'term': {'uuid.keyword': uuid}}}, size=1)
        if results['hits']['total']['value'] > 0:
            return True
        else:
            logging.error("No result found in ES")
            return False

    @classmethod 
    def check_metadata_collection(cls, uuid, es_ssl=False):
        if not (cls.metadata_collection_enabled and len(cls.indices) > 0):
            return True
        results = [cls._check_es(uuid, index, es_ssl) for index in cls.indices]
        assert all(results)

    def run_and_check_benchmark(self, run, desired_running_state="Running", desired_complete_state="Complete", default_timeout=default_timeout):
        run.start(desired_state=desired_running_state, default_timeout=default_timeout)
        try:
            results = run.wait(desired_state=desired_complete_state, default_timeout=default_timeout)
            assert results['status'] == desired_complete_state
            sleep(5)
            self.check_metadata_collection(results['uuid'])
        except (BenchmarkFailedError, BenchmarkTimeoutError) as err:
            assert False
