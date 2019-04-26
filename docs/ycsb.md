# YCSB

[YCSB](https://github.com/brianfrankcooper/YCSB) is a performance test kit for key-value and other cloud serving stores.

## Running YCSB

Given that you followed instructions to deploy operator,
you can modify [cr.yaml](../deploy/crds/benchmark_v1alpha1_benchmark_cr.yaml)

Note: please ensure you set 0 for other workloads if editing the
[cr.yaml](../deploy/crds/benchmark_v1alpha1_benchmark_cr.yaml) file otherwise
your resource file should look like this:

YCSB is a workload that requires a kubernetes self-hosted infrastructure on which to run its tests. The CR structure requires you to define the infra. Current infra systems deployable by the benchmark operator and supported for YCSB testing:

| Infrastructure | Support Status |
|----------------|----------------|
| Couchbase      | Working        |
| MongoDB        | Planned        |


```yaml
apiVersion: benchmark.example.com/v1alpha1
kind: Benchmark
metadata:
  name: example-ycsb-couchbase
  namespace: ripsaw
spec:
  infrastructure:
    name: couchbase
    args:
      servers:
        size: 1
      storage:
        use_persistent_storage: False
  workload:
    name: ycsb
    args:
      # To disable ycsb, set workers to 0
      # ycsb must be loaded after the infra it depends on
      workers: 1
      infra: couchbase
      driver: couchbase2
      workload: workloada
```

Once done creating/editing the resource file, you can run it by:

```bash
# kubectl apply -f deploy/crds/benchmark_v1alpha1_benchmark_cr.yaml # if edited the original one
# kubectl apply -f <path_to_file> # if created a new cr file
```

Deploying the above would result in first a the Couchbase cluster being stood up, then a temporaroy YCSB pod running to load the database data, and finally a YCSB benchmark pod running the workload.
