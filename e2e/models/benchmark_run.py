import yaml

class BenchmarkRun:
    def __init__(self, name, yaml_path): 
        with open(yaml_path, 'r') as file:
            self.yaml = yaml.full_load(file) 

    def apply():
        # do kube api logic and grab uuid
        self.uuid = uuid()
        self.pod = "pod_name"
        pass


    def wait(pod_name, retries, backoff, timeout):
        pass

    def check():
        pass



if __name__ == '__main__':
    run = BenchmarkRun("byowl", "/home/kwhitley/git/whitleykeith/benchmark-operator/test/e2e/benchmarks/byowl/base.yaml")
    print(run.yaml)


