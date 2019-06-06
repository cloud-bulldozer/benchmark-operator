# YCSB

[YCSB](https://github.com/brianfrankcooper/YCSB) is a performance test kit for key-value and other cloud serving stores.

## Running YCSB

Given that you followed instructions to deploy operator,
you can modify the [CR](../examples/multi/ycsb-couchbase.yaml) to your needs.

> NOTE: The above example CR deploys both the Couchbase infra and runs the YCSB benchmark on it.


YCSB is a workload that requires a kubernetes self-hosted infrastructure on which to run its tests. The CR structure requires you to define the infra. Current infra systems deployable by the benchmark operator and supported for YCSB testing:

| Infrastructure | Support Status |
|----------------|----------------|
| Couchbase      | Working        |
| MongoDB        | Planned        |

Your resource file may look like this:

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: ycsb-couchbase-benchmark
  namespace: ripsaw
spec:
  infrastructure:
    name: couchbase
    args:
      servers:
        # Typical deployment size is 3
        size: 3
      storage:
        use_persistent_storage: True
        class_name: "rook-ceph-block"
        volume_size: 10Gi
  workload:
    name: ycsb
    args:
      workers: 1
      infra: couchbase
      driver: couchbase2
      workload: workloada
```

Once done creating/editing the resource file, you can run it by:

```bash
# kubectl apply -f <path_to_file>
```

Deploying the above would result in first a the Couchbase cluster being stood up, then a temporaroy YCSB pod running to load the database data, and finally a YCSB benchmark pod running the workload.
