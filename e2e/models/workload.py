from os import listdir
from os.path import isfile, join
from e2e.models.benchmark_run import BenchmarkRun
from e2e.util.k8s import Cluster


class Workload:
    def __init__(self, name, cluster, benchmark_dir):
        self.name = name 
        self.cluster = cluster
        self.workload_dir = f"{benchmark_dir}/{name}"
        self.benchmark_runs = [
            BenchmarkRun(f.split('.')[0], join(self.workload_dir, f), self.cluster)
            for f in listdir(self.workload_dir) 
            if isfile(join(self.workload_dir, f)) and f.endswith(".yaml")
        ]

    def run_all(self):
        runs = []
        for run in self.benchmark_runs:
            run.start()
            run.wait()
            runs.append(run.metadata)
        return runs

    def run(self, run_name): 
        run = next((run for run in self.benchmark_runs if run.name == run_name), None)
        run.start()
        run.wait()
        return run.metadata


if __name__ == '__main__':
    cluster = Cluster()
    benchmark_dir = "/home/kwhitley/git/whitleykeith/benchmark-operator/e2e/benchmarks"
    workload = Workload("fiod", cluster, benchmark_dir)
    print(workload.run_all())
