# Kube-burner

## What is kube-burner?

Kube-burner is a tool that allows a user to perform scalability tests across Kubernetes and OpenShift clusters by creating thousands of objects. Kube-burner is developed in it's own repository at https://github.com/cloud-bulldozer/kube-burner
This ripsaw integration is meant to run only some workloads useful to measure certain performance KPIs of a cluster.

## Running kube-burner

Given that you followed instructions to deploy operator. Kube-burner needs an additional serviceaccount and clusterrole to run. Available at [kube-burner-role.yml](../resources/kube-burner-role.yml)
You can modify kube-burner's [cr.yaml](../resources/crds/ripsaw_v1alpha1_kube-burner_cr.yaml) to fit your requirements.

## Supported workloads

Ripsaw's kube-burner integration supports the following workloads:

- **cluster-density**: This workload is a cluster density focused test that creates a set of Deployments, Builds, Secret, Services and Routes across the cluster. This is a namespaced workload, meaning that kube-burner **will create as many namespaces with these objects as the configured job_iterations**. 
Each iteration of this workload creates the following objects:
  - 12 imagestreams
  - 3 buidconfigs
  - 6 builds
  - 1 deployment with 2 pod replicas (sleep) mounting two secrets each. *deployment-2pod*
  - 2 deployments with 1 pod replicas (sleep) mounting two secrets. *deployment-1pod*
  - 3 services, one pointing to *deployment-2pod*, and other two pointing to *deployment-1pod*.
  - 3 route. 1 pointing to the service *deployment-2pod* and other two pointing to *deployment-1pod*
  - 20 secrets

- **kubelet-density**: Creates a single namespace with a number of Deployments equal to **job_iterations**.
Each iteration of this workload creates the following object:
  - 1 pod. (sleep)

- **kubelet-density-heavy**. Creates a **single namespace with a number of applications equals to job_iterations**. This application consists on two deployments (a postgresql database and a simple client that generates some CPU load) and a service that is used by the client to reach the database.
Each iteration of this workload creates the following objects:
  - 1 deployment holding a postgresql database
  - 1 deployment holding a client application for the previous database
  - 1 service pointing to the postgresl database

The workload type is specified by the parameter `workload` from the `args` object of the configuration. Each workload supports several configuration parameters, detailed in the [configuration section](#configuration)

## Configuration

All kube-burner's workloads support the following parameters:

- **workload**: Type of kube-burner workload. As mentioned before, allowed values are cluster-density, kubelet-density and kubelet-density-heavy
- **default_index**: Elasticsearch index name. Defaults to __ripsaw-kube-burner__
- **prom_es_user**: Prometheus Elasticsearch user if required
- **prom_es_pass**: Prometheus Elasticsearch pass if required
- **job_iterations**: How many iterations to execute of the specified kube-burner workload
- **qps**: Limit object creation queries per second. Defaults to __5__
- **burst**: Maximum burst for throttle. Defaults to __10__
- **image**: Allows to use an alternative kube-burner container image. Defaults to `quay.io/cloud-bulldozer/kube-burner:latest`
- **wait_when_finished**: Makes kube-burner to wait for all objects created to be ready/completed before index metrics and finishing the job. Defaults to __true__
- **pod_wait**: Wait for all pods to be running before moving forward to the next job iteration. Defaults to __false__
- **verify_objects**: Verify object count after running each job. Defaults to __true__
- **error_on_verify**: Exit with rc 1 before indexing when object verification fails. Defaults to __false__
- **log_level**: Kube-burner log level. Allowed info and debug. Defaults to __info__
- **node_selector**: Pods deployed by the different workloads use this nodeSelector. This parameter consists of a dictionary like:

```yaml
node_selector:
  value: node-role.kubernetes.io/master
  key: ""
```
Where value defaults to __node-role.kubernetes.io/worker__ and key defaults to empty string ""

- **cleanup**: Delete old namespaces for the selected workload before starting a new benchmark. Defaults to __true__
- **wait_for**: List containing the objects Kind to wait for at the end of each iteration or job. This parameter only **applies the cluster-density workload**. If not defined wait for all objects. i.e: wait_for: ["Deployment"]
- **job_timeout**: Kube-burner job timeout in seconds. Defaults to __3600__ .Uses the parameter [activeDeadlineSeconds](https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup)
- **pin_server** and **tolerations**: Detailed in the section [Pin to server and tolerations](#Pin-to-server-and-tolerations)
- **step**: Prometheus step size, useful for long benchmarks. Defaults to 30s
- **metrics_profile**: kube-burner metric profile that indicates what prometheus metrics kube-burner will collect. Defaults to `metrics.yaml`. Detailed in the [Metrics section](#Metrics) of this document

kube-burner is able to collect complex prometheus metrics and index them in a ElasticSearch instance. This feature can be configured by the prometheus object of kube-burner's CR.

```yaml
spec:
  prometheus:
    server: https://search-cloud-perf-lqrf3jjtaqo7727m7ynd2xyt4y.us-west-2.es.amazonaws.com:443
    prom_url: https://prometheus-k8s.openshift-monitoring.svc.cluster.local:9091
    prom_token: prometheusToken
  workload:
```

Where:
- server: Points to a valid ElasticSearch endpoint. Full URL format required. i.e. https://elastic.instance.apps.com:9200
- prom_url: Points to a valid Prometheus endpoint. Full URL format required. i.e https://prometheus-k8s.openshift-monitoring.svc.cluster.local:9091
- prom_token: Refers to a valid prometheus token. It can be obtained with: `oc -n openshift-monitoring sa get-token prometheus-k8s`

## Metrics

kube-burner is able to collect Prometheus metrics using the time range of the benchmark. There are two metric profiles available at the moment.

- [metrics.yaml](../roles/kube-burner/files/metrics.yaml): This metric profile is indicated for benchmarks executed in small clusters. Since it gets metrics for several system pods from each node. Otherwise, we can reduce the number of indexed metrics (at the expense of granularity) with the parameter **step**.
- [metrics-aggregated.yaml](../roles/kube-burner/files/metrics-aggregated.yaml): This metric profile is indicated for benchmarks in large clusters. Since the metrics from the worker nodes and the infra nodes are aggregated and only metrics from master nodes are collected individually. Also the parameter **step** can be used to reduce the number of metrics (at the expense of granularity) that will be indexed.

By default the [metrics.yaml](metrics.yaml) profile is used. You can change this profile with the variable **metrics_profile**.

## Pin to server and tolerations

It's possible to pin kube-burner pod to a certain node using the `pin_server` parameter. This parameter is used in the job template as:

```jinja
{% if workload_args.pin_server is defined and workload_args.pin_server != "" %}
      nodeSelector:
        kubernetes.io/hostname: {{ workload_args.pin_server }}
{% endif %}
```

With the above we could configure the workload to run in a certain node with:

```yaml
workload:
  args:
    pin_server: ip-10-0-176-173
```

It's also possible to configure scheduling tolerations for the kube-burner pod. To do just pass a list with the desired tolerations as in the code snippet below:

```yaml
workload:
  args:
    tolerations:
    - key: role
      value: worker
      effect: NoSchedule
```
