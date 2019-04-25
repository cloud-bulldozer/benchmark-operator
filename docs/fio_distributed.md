# FIO Distributed

FIO (Flexible I/O Tester) has a native mechanism to run multiple servers concurrently and summarize
the results.

This workload will launch N number of FIO Servers and a single FIO Client which will kick off the
workload.

## Running Distributed FIO

Build your CR for Distributed FIO

```yaml
apiVersion: benchmark.example.com/v1alpha1
kind: Benchmark
metadata:
  name: fio-benchmark
  namespace: ripsaw
spec:
  workload:
    name: "fio_distributed"
    args:
      servers: 1
      jobname: test
      bs: 4k
      iodepth: 4
      runtime: 10
      rw: write
      filesize: 1
```

