# Benchmark Operator

The intent of this Operator is to deploy common workloads to establish
a performance baseline of Kubernetes cluster on your provider.

## Workloads status

| Workload                       | Use                    | Status in Operator | Reconciliation usage       | VM support (kubevirt) |
| ------------------------------ | ---------------------- | ------------------ | -------------------------- | --------------------- |
| [UPerf](docs/uperf.md)         | Network Performance    | Working            |  Used, default : 3second  | Preview               |
| [Iperf3](docs/iperf3.md)       | Network Performance    | Working            |  Used, default : 3second  | Not Supported         |
| [fio](docs/fio_distributed.md) | Storage IO             | Working            |  Used, default : 3second  | Working               |
| [Sysbench](docs/sysbench.md)   | System Performance     | Working            |  Used, default : 3second  | Not Supported         |
| [YCSB](docs/ycsb.md)           | Database Performance   | Working            |  Used, default : 3second  | Not Supported         |
| [Byowl](docs/byowl.md)         | User defined workload  | Working            |  Used, default : 3second  | Not Supported         |
| [Pgbench](docs/pgbench.md)     | Postgres Performance   | Working            |  Used, default : 3second  | Not Supported         |
| [Smallfile](docs/smallfile.md) | Storage IO Performance | Working            |  Used, default : 3second  | Not Supported         |
| [fs-drift](docs/fs-drift.md)   | Storage IO Longevity   | Working            |  Not used                 | Not Supported         |
| [hammerdb](docs/hammerdb.md)   | Database Performance   | Working            |  Used, default : 3second  | Not Supported         |
| [Vegeta](docs/vegeta.md)       | HTTP Performance       | Working            |  Used, default : 3second  | Not Supported         |


### Reconciliation

Previously the Benchmark Operator didn't properly take advantage of the reconciliation period. Going forward
we will make every attempt to utilize the reconciliation period.

Why did we decide to switch to this? Our operator would implement long running tasks, due to the nature of benchmarks.
However, long running tasks blocks the Operator, causing us to delete the Operator and re-create the operator to
un-block it. The benchmarks mentioned above that state `Used` for Reconciliation, no longer have this issue.

## Optional workload images
Optional locations for workload images can now be added easily without the need to rebuild the operator.
To do so in the workload args section of the CR add image: [location]

NOTE: This is not a required arguement. If omitted it will default to the currently verified workload image.
Additionally, this is not enabled for YCSB

For Example:

```
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: example-benchmark
  namespace: my-ripsaw
spec:
  elasticsearch:
    server: "my-es.foo.bar"
    port: 9200
  metadata_collection: true
  cleanup: false
  workload:
    name: "foo"
    args:
      image: my.location/foo:latest
```

## Installation
[Installation](docs/installation.md)

## Contributing
[Contributing](CONTRIBUTE.md)

## Metadata Collection
[Metadata Collection](docs/metadata.md)

## Cerberus Integration
[Cerberus Integration](docs/cerberus.md)

## Community
Key Members(slack_usernames): aakarsh, dry923, rsevilla or rook
* [**#sig-scalability on Kubernetes Slack**](https://kubernetes.slack.com)
* [**#forum-perfscale on CoreOS Slack**](https://coreos.slack.com)
