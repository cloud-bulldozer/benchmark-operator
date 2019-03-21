# Sybench

[Sysbench](https://github.com/akopytov/sysbench) provides benchmarking capabilities for Linux. sysbench supports testing CPU, memory, file I/O, mutex performance, and even MySQL benchmarking

## Running Sysbench

Given that you followed instructions to deploy operator,
you can modify [cr.yaml](../deploy/crds/bench_v1alpha1_bench_cr.yaml)

Note: please ensure you set 0 for other workloads if editing the
[cr.yaml](../deploy/crds/bench_v1alpha1_bench_cr.yaml) file otherwise
your resource file should look like this:

```yaml
apiVersion: bench.example.com/v1alpha1
kind: Bench
metadata:
  name: example-bench
spec:
  enabled: true
  tests:
  - name: cpu
    parameters:
      cpu-max-prime: 200
```

Name here refers to testname and can be cpu or fileio or memory etc and the parameters are the parametes for the particular test.
You can find more information at [sysbench documentation](https://github.com/akopytov/sysbench#general-syntax) and online.

Once done creating/editing the resource file, you can run it by:

```bash
# kubectl create -f deploy/crds/bench_v1alpha1_bench_cr.yaml # if edited the original one
# kubectl create -f <path_to_file> # if created a new cr file
```

Deploying the above(running cpu) would result in

```bash
# kubectl get pods
NAME                                 READY   STATUS              RESTARTS   AGE
benchmark-operator-6bfccf9dc-cfzvc   1/1     Running             0          7m18s
example-bench-sysbench-9cvff         0/1     ContainerCreating   0          51s
```

You can look at results by using logs functionality - `kubectl logs <client>`,
it should look like:
```bash
# kubectl logs -f example-bench-sysbench-9cvff
WARNING: the --test option is deprecated. You can pass a script name or path on the command line without any options.
sysbench 1.0.9 (using system LuaJIT 2.0.4)

Running the test with following options:
Number of threads: 1
Initializing random number generator from current time


Prime numbers limit: 2000

Initializing worker threads...

Threads started!

CPU speed:
    events per second:  5503.35

General statistics:
    total time:                          10.0003s
    total number of events:              55067

Latency (ms):
         min:                                  0.11
         avg:                                  0.18
         max:                                 78.79
         95th percentile:                      0.31
         sum:                               9958.03

Threads fairness:
    events (avg/stddev):           55067.0000/0.00
    execution time (avg/stddev):   9.9580/0.00
```
