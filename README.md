# Benchmark Operator

The intent of this Operator is to deploy common workloads to establish
a performance baseline of Kubernetes cluster on your provider.

## Workloads status

| Workload                       | Use                   | Status in Operator |
| ------------------------------ | --------------------  | ------------------ |
| [UPerf](docs/uperf.md)         | Network Performance   | Working            |
| [Iperf3](docs/iperf3.md)       | Network Performance   | Working            |
| [fio](docs/fio_distributed.md) | Storage IO            | Working            |
| [Sysbench](docs/sysbench.md)   | System Performance    | Working            |
| [YCSB](docs/ycsb.md)           | Database Performance  | Preview            |
| [Byowl](docs/byowl.md)         | User defined workload | Working            |
| [Pgbench](docs/pgbench.md)     | Postgres Performance  | Working            |


## Installation
[Installation](docs/installation.md)

## Contributing
[Contributing](CONTRIBUTE.md)

## Community
Key Members(slack_usernames): aakarsh, dblack or rook
* [**#sig-scalability on Kubernetes Slack**](https://kubernetes.slack.com)
* [**#forum-kni-perfscale on CoreOS Slack**](https://coreos.slack.com)
