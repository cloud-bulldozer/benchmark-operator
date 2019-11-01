# Benchmark Operator

The intent of this Operator is to deploy common workloads to establish
a performance baseline of Kubernetes cluster on your provider.

## Workloads status

| Workload                       | Use                    | Status in Operator | Reconciliation usage       |
| ------------------------------ | ---------------------- | ------------------ | -------------------------- |
| [UPerf](docs/uperf.md)         | Network Performance    | Working            |  Used, default : 30second  |
| [Iperf3](docs/iperf3.md)       | Network Performance    | Working            |  Used, default : 30second  |
| [fio](docs/fio_distributed.md) | Storage IO             | Working            |  Used, default : 30second  |
| [Sysbench](docs/sysbench.md)   | System Performance     | Working            |  Used, default : 30second  |
| [YCSB](docs/ycsb.md)           | Database Performance   | Working            |  Not used                  |
| [Byowl](docs/byowl.md)         | User defined workload  | Working            |  Used, default : 30second  |
| [Pgbench](docs/pgbench.md)     | Postgres Performance   | Working            |  Not used                  |
| [Smallfile](docs/smallfile.md) | Storage IO Performance | Working            |  Used, default : 30second  |
| [fs-drift](docs/fs-drift.md)   | Storage IO Longevity   | Working            |  Not used                  |
| [hammerdb](docs/hammerdb.md)   | Database Performance   | Working            |  Not used                  |


### Reconciliation

Previously the Benchmark Operator didn't properly take advantage of the reconciliation period. Going forward
we will make every attempt to utilize the reconciliation period.

Why did we decide to switch to this? Our operator would implement long running tasks, due to the nature of benchmarks.
However, long running tasks blocks the Operator, causing us to delete the Operator and re-create the operator to
un-block it. The benchmarks mentioned above that state `Used` for Reconciliation, no longer have this issue.

### Reconciliation issue with YCSB and PGBench

These two bencharmks are written in a way that doesn't allow for reconciliation to be implemented. To take
advantage of the reconciliation loop, these two benchmarks need to be rewritten.

## Installation
[Installation](docs/installation.md)

## Contributing
[Contributing](CONTRIBUTE.md)

## Metadata Collection
[Metadata Collection](docs/metadata.md)

## Community
Key Members(slack_usernames): aakarsh, dblack or rook
* [**#sig-scalability on Kubernetes Slack**](https://kubernetes.slack.com)
* [**#forum-kni-perfscale on CoreOS Slack**](https://coreos.slack.com)
