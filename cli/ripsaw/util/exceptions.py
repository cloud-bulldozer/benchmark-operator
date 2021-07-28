class BenchmarkFailedError(Exception):
    def __init__(self, name, uuid, msg=None):
        if msg is None:
            msg = f"The benchmark {name} with uuid {uuid} failed"
        super(BenchmarkFailedError, self).__init__(msg)
        self.name = name
        self.uuid = uuid

class BenchmarkNotStartedError(Exception):
    def __init__(self, name, msg=None):
        if msg is None:
            msg = f"The benchmark {name} has not started yet"
        
        super(BenchmarkNotStartedError, self).__init__(msg)

class BenchmarkTimeoutError(Exception):
    def __init__(self, name, msg=None):
        if msg is None:
            msg = f"The benchmark {name} timed out"
        
        super(BenchmarkTimeoutError, self).__init__(msg)
        self.name = name



class PodsNotFoundError(Exception):
    def __init__(self, msg=None):
        if msg is None:
            msg = f"No Pods found"
        super(PodsNotFoundError, self).__init__(msg)