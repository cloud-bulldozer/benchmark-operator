import yaml
from benedict import benedict
from ripsaw.clients.k8s import Cluster 
from ripsaw.util.exceptions import BenchmarkNotStartedError
from ripsaw.util import logging

logger = logging.get_logger(__name__)

class Benchmark:
    def __init__(self, file, cluster): 
        self.yaml = benedict(yaml.full_load(file), keypath_separator=",") 
        self.cluster = cluster
        self.name = self.yaml['metadata']['name']
        self.namespace = self.yaml['metadata']['namespace']
        self.metadata = {}


    def update_spec(self, key_path, new_value):
        self.yaml[key_path] = new_value


    def run(self, timeout=600):
        self.metadata = self.cluster.create_benchmark(self.yaml)
        logger.info(f"Benchmark {self.name} created")
        self.wait(timeout=timeout)
        return self.metadata

    def wait(self, desired_state="Complete", timeout=600):
        if self.metadata == {}:
            raise BenchmarkNotStartedError(self.name)
        self.cluster.wait_for_benchmark(self.name, self.namespace, desired_state=desired_state, timeout=timeout)
        self.metadata = self.cluster.get_benchmark_metadata(self.name, self.namespace)
        return self.metadata

    def cleanup(self): 
        try: 
            self.cluster.delete_benchmark(self.name, self.namespace)
        except Exception as err:
            if err.status != 404:
                raise err

    def get_metadata(self):
        return self.cluster.get_benchmark_metadata(self.name, self.namespace)
