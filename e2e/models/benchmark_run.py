import yaml
from benedict import benedict
from util.k8s import Cluster 
from util.exceptions import BenchmarkNotStartedError

class BenchmarkRun:
    def __init__(self, name, yaml_path, cluster): 
        with open(yaml_path, 'r') as file:
            self.yaml = benedict(yaml.full_load(file)) 
        self.cluster = cluster
        self.name = name
        self.resource_name = self.yaml['metadata']['name']
        self.resource_namespace = self.yaml['metadata']['namespace']
        self.metadata = {}


    def update_spec(self, key_path, new_value):
        self.yaml[key_path] = new_value


    def start(self):
        self.metadata = self.cluster.create_benchmark(self.yaml)
        return self.metadata

    def wait(self, desired_state="Complete"):
        if self.metadata == {}:
            raise BenchmarkNotStartedError(self.name)
        self.cluster.wait_for_benchmark(self.resource_name, self.resource_namespace, desired_state=desired_state)
        self.metadata = self.cluster.get_benchmark_metadata(self.resource_name, self.resource_namespace)
        return self.metadata

    def cleanup(self): 
        try: 
            self.cluster.delete_benchmark(self.resource_name, self.resource_namespace)
        except Exception as err:
            if err.status != 404:
                raise err

    def get_metadata(self):
        return self.cluster.get_benchmark_metadata(self.resource_name, self.resource_namespace)
