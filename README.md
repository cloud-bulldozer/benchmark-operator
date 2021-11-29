# Benchmark Operator

The intent of this Operator is to deploy common workloads to establish
a performance baseline of Kubernetes cluster on your provider.


## Installation (Default)
The easiest way to install the operator is through the operator-sdk methods provided in the `Makefile`.

```bash
git clone https://github.com/cloud-bulldozer/benchmark-operator
cd benchmark-operator
make deploy
```

If you wish to build a version of the operator from your local copy of the repo, you can run

```bash
git clone https://github.com/cloud-bulldozer/benchmark-operator
cd benchmark-operator
make image-build image-push deploy IMG=$YOUR_IMAGE
```

> Note: building the image requires podman

## Installation (Helm)

Installing the benchmark-operator via Helm can be done with the following commands. This requires
your machine to have Helm installed. [Install Helm](https://helm.sh/docs/intro/install/)

> Note: If running on openshift you'll need to run this command before installing the chart. `oc adm policy -n benchmark-operator add-scc-to-user privileged -z benchmark-operator`



```bash
git clone https://github.com/cloud-bulldozer/benchmark-operator
cd benchmark-operator/charts/benchmark-operator
kubectl create namespace benchmark-operator
oc adm policy -n benchmark-operator add-scc-to-user privileged -z benchmark-operator # Openshift Only
helm install benchmark-operator . -n benchmark-operator --create-namespace
```

To delete this release, you can do so with the following command:

```bash
helm uninstall benchmark-operator -n benchmark-operator
```



## Workloads status

| Workload                       | Use                    | ElasticSearch indexing  | Reconciliation usage       | VM support (kubevirt) | Kata Containers | CI Tested |
| ------------------------------ | ---------------------- | ------------------ | -------------------------- | --------------------- | --------------- | ------------ |
| [UPerf](docs/uperf.md)         | Network Performance    | Yes                |  Used, default : 3second  | Working                | Working         | Yes |
| [Iperf3](docs/iperf3.md)       | Network Performance     | No                 |  Used, default : 3second  | Not Supported          | Preview         | Yes |
| [fio](docs/fio_distributed.md) | Storage IO             | Yes                |  Used, default : 3second  | Working                | Working         | Yes |
| [Sysbench](docs/sysbench.md)   | System Performance     | No                 |  Used, default : 3second  | Not Supported          | Preview         | Yes |
| [YCSB](docs/ycsb.md)           | Database Performance   | Yes            |  Used, default : 3second  | Not Supported          | Preview         | Yes |
| [Byowl](docs/byowl.md)         | User defined workload  | Yes            |  Used, default : 3second  | Not Supported          | Preview         | Yes |
| [Pgbench](docs/pgbench.md)     | Postgres Performance   | Yes            |  Used, default : 3second  | Not Supported          | Preview         | Yes |
| [Smallfile](docs/smallfile.md) | Storage IO Performance | Yes            |  Used, default : 3second  | Not Supported          | Preview         | Yes |
| [fs_drift](docs/fs_drift.md)   | Storage IO Longevity   | Yes            |  Not used                 | Not Supported          | Preview         | Yes |
| [hammerdb](docs/hammerdb.md)   | Database Performance   | Yes            |  Used, default : 3second  |  Working                | Preview         | Yes |
| [Service Mesh](docs/servicemesh.md) | Microservices     | No            |  Used, default : 3second   | Not Supported         | Preview         | No |
| [Vegeta](docs/vegeta.md)       | HTTP Performance       | Yes            |  Used, default : 3second  | Not Supported          | Preview         | Yes |
| [Scale Openshift](docs/scale_openshift.md) | Scale Openshift Cluster       | Yes            |  Used, default : 3second  | Not Supported         | Preview        | Yes |
| [stressng](docs/stressng.md)   | Stress system resources | Yes            |  Used, default: 3second  | Working               | Preview        | Yes |
| [kube-burner](docs/kube-burner.md)  | k8s Performance   | Yes            |  Used, default : 3second  | Not Supported          | Preview         | Yes |
| [cyclictest](docs/cyclictest.md)  | Real-Time Performance   | Yes       |  Used, default : 3second  | Not Supported          | Preview         | No |
| [oslat](docs/oslat.md)         | Real-Time Latency      | Yes           |  Used, default : 3second   | Not Supported          | Preview         | No |
| [testpmd](docs/testpmd.md)         | TestPMD DPDK App      | No           |  Used   | Not Supported          | Preview         | No |
| [Flent](docs/flent.md)         | Network Performance    | Yes           |  Used, default : 3second  | Not Supported          | Not Supported   | Yes |
| [Log-Generator](docs/log_generator.md)         | Log Throughput to Backend    | Yes           |  Used, default : 3second  | Not Supported          | Yes  | Yes |
| [Image-Pull](docs/image_pull.md)         | Time to Pull Image from Container Repo    | Yes           |  Used, default : 3second  | Not Supported          | Yes  | Yes |

### Reconciliation

Previously the Benchmark Operator didn't properly take advantage of the reconciliation period. Going forward
we will make every attempt to utilize the reconciliation period.

Why did we decide to switch to this? Our operator would implement long running tasks, due to the nature of benchmarks.
However, long running tasks blocks the Operator, causing us to delete the Operator and re-create the operator to
un-block it. The benchmarks mentioned above that state `Used` for Reconciliation, no longer have this issue.

# E2E tests
Benchmark-operator includes a series of end 2 end tests that can be triggered in local. More info in the [documentation.](docs/e2e-ci.md#running-in-local)

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
  namespace: benchmark-operator
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

## Optional debug out for benchmark-wrapper workloads
Workloads that are triggered through [benchmark-wrapper](https://github.com/cloud-bulldozer/benchmark-wrapper)
can optionally pass the debug flag through the workload CR.

NOTE: This is not a required arguement. If omitted it will default to the default logging level of
the benchmark-wrapper

For Example:

```
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: example-benchmark
  namespace: benchmark-operator
spec:
  elasticsearch:
    url: "http://my-es.foo.bar:80"
  metadata_collection: true
  cleanup: false
  workload:
    name: snafu_workload
    args:
      debug: true
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
  namespace: benchmark-operator
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

## Contributing
[Contributing](CONTRIBUTING.md)

## Metadata Collection
[Metadata Collection](docs/metadata.md)

## Indexing to Elasticsearch
[Indexing to Elasticsearch](docs/elastic.md)

## Capturing Prometheus Data
[Capturing Prometheus Data](docs/prometheus.md)

## Cache dropping
[Cache dropping](docs/cache_dropping.md)

## Community
Key Members(slack_usernames):  sejug, mohit, dry923, rsevilla or rook
* [**#sig-scalability on Kubernetes Slack**](https://kubernetes.slack.com)
* [**#forum-perfscale on CoreOS Slack**](https://coreos.slack.com)
