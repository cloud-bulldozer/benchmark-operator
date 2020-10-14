import yaml
from e2e.util.k8s import Cluster 

class BenchmarkRun:
    def __init__(self, name, yaml_path, cluster): 
        with open(yaml_path, 'r') as file:
            self.yaml = yaml.full_load(file) 
        self.cluster = cluster
        self.name = name
        self.metadata = {}

    def start(self):
        self.metadata = self.cluster.create_benchmark(self.yaml)
        return self.metadata

    def wait(self):
        if self.metadata == {}:
            print("Benchmark has not been started, so doing that first")
            self.start()
        self.cluster.wait_for_benchmark(self.metadata['name'], self.metadata['namespace'], desired_state="Complete")
        self.metadata = self.cluster.get_benchmark_metadata(self.metadata['name'], self.metadata['namespace'])


