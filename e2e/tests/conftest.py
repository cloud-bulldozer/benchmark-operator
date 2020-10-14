import pytest 
import os

class Helpers:
    @staticmethod
    def all_runs_passed(runs):
         return all(run.get('status', "") == "Complete" for run in runs)  

    @staticmethod
    def get_benchmark_dir():
        benchmark_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(__file__))), "benchmarks")
        print(benchmark_dir)
        return benchmark_dir



@pytest.fixture
def helpers():
    return Helpers