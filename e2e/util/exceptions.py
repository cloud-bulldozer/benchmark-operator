class BenchmarkFailedError(Exception):
    def __init__(self, benchmark_name, uuid, msg=None):
        if msg is None:
            msg = f"The benchmark {benchmark_name} with uuid {uuid} failed"
        super(BenchmarkFailedError, self).__init__(msg)
        self.benchmark_name = benchmark_name
        self.uuid = uuid