# Benchmark Operator

The intent of this Operator is to deploy common workloads to establish
a performance baseline of Kubernetes cluster on your provider.

## Installation

Installing the benchmark-operator is easiest by using the helm chart and can be done with the following commands. This requires 
your machine to have Helm installed. [Install Helm](https://helm.sh/docs/intro/install/)

> Note: If running on openshift you'll need to run this command before installing the chart. `oc adm policy -n my-ripsaw add-scc-to-user privileged -z benchmark-operator`



```bash
git clone https://github.com/cloud-bulldozer/benchmark-operator
cd benchmark-operator/charts/benchmark-operator
helm install benchmark-operator . -n my-ripsaw --create-namespace
```

To delete this release, you can do so with the following command:

```bash
helm delete benchmark-operator -n my-ripsaw --purge
```



## Workloads status

| Workload                       | Use                    | ElasticSearch indexing  | Reconciliation usage       | VM support (kubevirt) | Kata Containers | CI Tested |
| ------------------------------ | ---------------------- | ------------------ | -------------------------- | --------------------- | --------------- | ------------ |
| [UPerf](docs/uperf.md)         | Network Performance    | Yes                |  Used, default : 3second  | Working                | Working         | Yes |
| [Iperf3](docs/iperf.md)       | Network Performance     | No                 |  Used, default : 3second  | Not Supported          | Preview         | Yes |
| [fio](docs/fio_distributed.md) | Storage IO             | Yes                |  Used, default : 3second  | Working                | Working         | Yes |
| [Sysbench](docs/sysbench.md)   | System Performance     | No                 |  Used, default : 3second  | Not Supported          | Preview         | Yes |
| [YCSB](docs/ycsb.md)           | Database Performance   | Yes            |  Used, default : 3second  | Not Supported          | Preview         | Yes |
| [Byowl](docs/byowl.md)         | User defined workload  | Yes            |  Used, default : 3second  | Not Supported          | Preview         | Yes |
| [Pgbench](docs/pgbench.md)     | Postgres Performance   | Yes            |  Used, default : 3second  | Not Supported          | Preview         | Yes |
| [Smallfile](docs/smallfile.md) | Storage IO Performance | Yes            |  Used, default : 3second  | Not Supported          | Preview         | Yes |
| [fs-drift](docs/fs-drift.md)   | Storage IO Longevity   | Yes            |  Not used                 | Not Supported          | Preview         | Yes |
| [hammerdb](docs/hammerdb.md)   | Database Performance   | Yes            |  Used, default : 3second  | Not Supported          | Preview         | Yes |
| [Service Mesh](docs/servicemesh.md) | Microservices     | No            |  Used, default : 3second   | Not Supported         | Preview         | No |
| [Vegeta](docs/vegeta.md)       | HTTP Performance       | Yes            |  Used, default : 3second  | Not Supported          | Preview         | Yes |
| [Scale Openshift](docs/scale_openshift.md) | Scale Openshift Cluster       | Yes            |  Used, default : 3second  | Not Supported         | Preview        | Yes |
| [stressng](docs/stressng.md)   | Stress system resources | Yes            |  Used, default: 3second  | Not Supported         | Preview        | Yes |
| [kube-burner](docs/kube-burner.md)  | k8s Performance   | Yes            |  Used, default : 3second  | Not Supported          | Preview         | Yes |
| [cyclictest](docs/cyclictest.md)  | Real-Time Performance   | Yes       |  Used, default : 3second  | Not Supported          | Preview         | No |
| [oslat](docs/oslat.md)         | Real-Time Latency      | Yes           |  Used, default : 3second   | Not Supported          | Preview         | No |
| [testpmd](docs/testpmd.md)         | TestPMD DPDK App      | No           |  Used   | Not Supported          | Preview         | No |

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
Additionally, this is *NOT* enabled for YCSB

For Example:

```
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: example-benchmark
  namespace: my-ripsaw
spec:
  elasticsearch:
    url: "http://my-es.foo.bar:80"
  metadata_collection: true
  cleanup: false
  workload:
    name: "foo"
    args:
      image: my.location/foo:latest
```

## User Provided UUID
All benchmarks in the benchmark-operator utilize a UUID for tracking and indexing purposes. This UUID is,
by default, generated when the workload is first started. However, if desired, a user provided UUID can
be added to the workload cr.

*NOTE: The provided UUID must be in format XXXXX-XXXXX-XXXXX*

For Example:
```
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: example-benchmark
  namespace: my-ripsaw
spec:
  uuid: 6060004a-7515-424e-93bb-c49844600dde
  elasticsearch:
    url: "http://my-es.foo.bar:80"
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

## Indexing to Elasticsearch
[Indexing to Elasticsearch](docs/elastic.md)

## Capturing Prometheus Data
[Capturing Prometheus Data](docs/prometheus.md)

## Cache dropping
[Cache dropping](docs/cache_dropping.md)

## Community
Key Members(slack_usernames): ravi, mohit, dry923, rsevilla or rook
* [**#sig-scalability on Kubernetes Slack**](https://kubernetes.slack.com)
* [**#forum-perfscale on CoreOS Slack**](https://coreos.slack.com)
