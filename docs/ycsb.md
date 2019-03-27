# YCSB

[YCSB](https://github.com/brianfrankcooper/YCSB) is a performance test kit for key-value and other cloud serving stores.

## Running YCSB

Given that you followed instructions to deploy operator,
you can modify [cr.yaml](../deploy/crds/bench_v1alpha1_bench_cr.yaml)

Note: please ensure you set 0 for other workloads if editing the
[cr.yaml](../deploy/crds/bench_v1alpha1_bench_cr.yaml) file otherwise
your resource file should look like this:

YCSB is a workload that requires a kubernetes self-hosted infrastructure on which to run its tests. The CR structure requires you to define the infra. Current infra systems deployable by the benchmark operator and supported for YCSB testing:

| Infrastructure | Support Status |
|----------------|----------------|
| Couchbase      | Working        |
| MongoDB        | Planned        |


```yaml
apiVersion: bench.example.com/v1alpha1
kind: Bench
metadata:
  name: example-bench
spec:
  couchbase: 
    # To disable couchbase, set servers.size to 0
    # Typical deployment size is 3
    servers:
      size: 3
    storage:
      use_persistent_storage: True
      class_name: "rook-ceph-block"
      volume_size: 10Gi
    on_openshift: True
  ycsb:
    # To disable ycsb, set workers to 0
    # ycsb must be loaded after the infra it depends on
    workers: 1
    infra: couchbase
    driver: couchbase2
    workload: workloada
```

Once done creating/editing the resource file, you can run it by:

```bash
# kubectl create -f deploy/crds/bench_v1alpha1_bench_cr.yaml # if edited the original one
# kubectl create -f <path_to_file> # if created a new cr file
```

Deploying the above would result in first a the Couchbase cluster being stood up, then a temporaroy YCSB pod running to load the database data, and finally a YCSB benchmark pod running the workload.
