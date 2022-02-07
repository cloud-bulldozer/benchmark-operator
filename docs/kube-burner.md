- [Kube-burner](#kube-burner)
  - [What is kube-burner?](#what-is-kube-burner)
  - [Running kube-burner](#running-kube-burner)
  - [Supported workloads](#supported-workloads)
  - [Configuration](#configuration)
  - [Metrics](#metrics)
  - [Pin to server and tolerations](#pin-to-server-and-tolerations)
  - [Using a remote configuration for kube-burner](#using-a-remote-configuration-for-kube-burner)
  - [Alerting](#alerting)


# Kube-burner

## What is kube-burner?

Kube-burner is a tool that allows a user to perform scalability tests across Kubernetes and OpenShift clusters by creating thousands of objects. Kube-burner is developed in it's own repository at https://github.com/cloud-bulldozer/kube-burner
The benchmark-operator integration here is meant to run only some workloads useful to measure certain performance KPIs of a cluster.

## Running kube-burner

Given that you followed instructions to deploy benchmark-operator. Kube-burner needs an additional serviceaccount and clusterrole to run. Available at [kube-burner-role.yml](../resources/kube-burner-role.yml)
You can modify kube-burner's [cr.yaml](../config/samples/kube-burner/cr.yaml) to fit your requirements.

----

## Supported workloads

Ripsaw's kube-burner integration supports the following workloads:

- **cluster-density**: This workload is a cluster density focused test that creates a set of Deployments, Builds, Secret, Services and Routes across the cluster. This is a namespaced workload, meaning that kube-burner **will create as many namespaces with these objects as the configured job_iterations**. 
Each iteration of this workload creates the following objects:
  - 12 imagestreams
  - 3 buidconfigs
  - 6 builds
  - 1 deployment with 2 pod replicas (sleep) mounting two secrets and two configmaps each. *deployment-2pod*
  - 2 deployments with 1 pod replicas (sleep) mounting two secrets and two configmaps. *deployment-1pod*
  - 3 services, one pointing to *deployment-2pod*, and other two pointing to *deployment-1pod*.
  - 3 route. 1 pointing to the service *deployment-2pod* and other two pointing to *deployment-1pod*
  - 10 secrets
  - 10 configmaps

- **node-density**: Creates a single namespace with a number of Deployments equal to **job_iterations**.
Each iteration of this workload creates the following object:
  - 1 pod. (sleep)

- **node-density-heavy**. Creates a **single namespace with a number of applications equals to job_iterations**. This application consists on two deployments (a postgresql database and a simple client that generates some CPU load) and a service that is used by the client to reach the database.
Each iteration of this workload creates the following objects:
  - 1 deployment holding a postgresql database
  - 1 deployment holding a client application for the previous database
  - 1 service pointing to the postgresl database

- **node-density-cni**. Creates a **single namespace with a number of applications equals to job_iterations**. This application consists on two deployments (a node.js webserver and a simple client that curls the webserver) and a service that is used by the client to reach the webserver.
Each iteration of this workload creates the following objects:
  - 1 deployment holding a node.js webserver
  - 1 deployment holding a client application for curling the webserver
  - 1 service pointing to the webserver

    The Readiness Probe of the client pod depends on being able to reach the webserver so that the PodReady latencies collected by kube-burner reflect network connectivity.

- **node-density-cni-policy**. Creates a **single namespace with a number of applications equals to job_iterations**. This application consists on two deployments (a node.js webserver and a simple client that curls the webserver) and a service that is used by the client to reach the webserver.
Each iteration of this workload creates the following objects:
  - 1 deployment holding a node.js webserver
  - 1 deployment holding a client application for curling the webserver
  - 1 service pointing to the webserver

    A NetworkPolicy to deny all connections is created in the namspace first and then NetworkPolicies specifically applying the connection of each client-webserver pair are applied. The Readiness Probe of the client pod depends on being able to reach the webserver so that the PodReady latencies collected by kube-burner reflect network connectivity.


- **max-namespaces**: This workload is a cluster limits focused test which creates maximum possible namespaces across the cluster. This is a namespaced workload, meaning that kube-burner **will create as many namespaces with these objects as the configured job_iterations**.
  - 1 deployment holding a postgresql database
  - 5 deployments consisting of a client application for the previous database
  - 1 service pointing to the postgresl database
  - 10 secrets

- **max-services**: This workload is a cluster limits focused test which creates maximum possible services per namespace. It **will create a single namespace, each iteration of this workload will populate that namespace with these objects:**
  - 1 simple application deployment (hello-openshift)
  - 1 service pointing to the previous deployment

- **pod-density**: Creates a single namespace with a number of Deployments equal to **job_iterations**. This workload is similar to node-density except is used to create a large number of pods spread across the cluster instead of specifically loading up each node with a given number of pods as in `node-density`.
Each iteration of this workload creates the following object:
  - 1 pod. (sleep)

- **concurrent-builds**: Creates a buildconfig, imagestream and corresponding build for a set application. **This will create as many namespaces with these objects as the configured job_iterations**. 
See https://github.com/cloud-bulldozer/e2e-benchmarking/tree/master/workloads/kube-burner for example parameters for each application
Each iteration of this workload creates the following object:
  - 1 imagestream (dependent on application type set)
  - 1 buildconfig (also dependent on application type set)
  - 1 build created from buildconfig 
  
The workload type is specified by the parameter `workload` from the `args` object of the configuration. Each workload supports several configuration parameters, detailed in the [configuration section](#configuration)

## Configuration

All kube-burner's workloads support the following parameters:

- **``workload``**: Type of kube-burner workload. As mentioned before, allowed values are cluster-density, node-density and node-density-heavy
- **``default_index``**: ElasticSearch index name. Defaults to __ripsaw-kube-burner__
- **``job_iterations``**: How many iterations to execute of the specified kube-burner workload
- **``qps``**: Limit object creation queries per second. Defaults to __5__
- **``burst``**: Maximum burst for throttle. Defaults to __10__
- **``image``**: Allows to use an alternative kube-burner container image. Defaults to `quay.io/cloud-bulldozer/kube-burner:latest`
- **``wait_when_finished``**: Makes kube-burner to wait for all objects created to be ready/completed before index metrics and finishing the job. Defaults to __true__
- **``pod_wait``**: Wait for all pods to be running before moving forward to the next job iteration. Defaults to __false__
- **``verify_objects``**: Verify object count after running each job. Defaults to __true__
- **``error_on_verify``**: Exit with rc 1 before indexing when object verification fails. Defaults to __false__
- **``log_level``**: Kube-burner log level. Allowed info and debug. Defaults to __info__
- **``node_selector``**: Pods deployed by the different workloads use this nodeSelector. This parameter consists of a dictionary like:

```yaml
node_selector:
  key: node-role.kubernetes.io/master
  value: ""
```
Where key defaults to __node-role.kubernetes.io/worker__ and value defaults to empty string ""

- **``cleanup``**: Delete old namespaces for the selected workload before starting a new benchmark. Defaults to __true__
- **``wait_for``**: List containing the objects Kind to wait for at the end of each iteration or job. This parameter only **applies the cluster-density workload**. If not defined wait for all objects. i.e: wait_for: ["Deployment"]
- **``job_timeout``**: Kube-burner job timeout in seconds. Defaults to __3600__ .Uses the parameter [activeDeadlineSeconds](https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup)
- **``pin_server``** and **``tolerations``**: Detailed in the section [Pin to server and tolerations](#Pin-to-server-and-tolerations)
- **``step``**: Prometheus step size, useful for long benchmarks. Defaults to 30s
- **``metrics_profile``**: kube-burner metric profile that indicates what prometheus metrics kube-burner will collect. Defaults to `metrics.yaml` in node-density workloads and `metrics-aggregated.yaml` in the remaining. Detailed in the [Metrics section](#Metrics) of this document
- **``runtime_class``** : If this is set, the benchmark-operator will apply the runtime_class to the podSpec runtimeClassName.
- **``annotations``** : If this is set, the benchmark-operator will set the specified annotations on the pod's metadata.
- **``extra_env_vars``** : This dictionary defines a set of fields that will be injected to the kube-burner pod as environment variables. e.g. `extra_env_vars: {"foo": "bar", "foo2": "bar2"}`

kube-burner is able to collect complex prometheus metrics and index them in a ElasticSearch. This feature can be configured by the prometheus object of kube-burner's CR.

```yaml
spec:
  prometheus:
    es_url: http://foo.esserver.com:9200
    prom_url: https://prometheus-k8s.openshift-monitoring.svc.cluster.local:9091
    prom_token: prometheusToken
  workload:
```

Where:
- **``es_url``**: Points to a valid ElasticSearch endpoint. Full URL format required. i.e. https://elastic.instance.apps.com:9200
- **``prom_url``**: Points to a valid Prometheus endpoint. Full URL format required. i.e https://prometheus-k8s.openshift-monitoring.svc.cluster.local:9091
- **``prom_token``**: Refers to a valid prometheus token. It can be obtained with: `oc -n openshift-monitoring sa get-token prometheus-k8s`

**Note**: It's possible to index documents in an authenticated ES endpoint using the notation `http(s)://[username]:[password]@[address]:[port]` in the es_url parameter.

## Metrics

kube-burner is able to collect Prometheus metrics using the time range of the benchmark. There are two metric profiles available at the moment.

- [metrics.yaml](../roles/kube-burner/files/metrics.yaml): This metric profile is indicated for benchmarks executed in small clusters. Since it gets metrics for several system pods from each node. Otherwise, we can reduce the number of indexed metrics (at the expense of granularity) with the parameter **step**.
- [metrics-aggregated.yaml](../roles/kube-burner/files/metrics-aggregated.yaml): This metric profile is indicated for benchmarks in large clusters. Since the metrics from the worker nodes and the infra nodes are aggregated and only metrics from master nodes are collected individually. Also the parameter **step** can be used to reduce the number of metrics (at the expense of granularity) that will be indexed.

By default the [metrics.yaml](../roles/kube-burner/files/metrics-aggregated.yaml) profile is used  in node-density workloads and `metrics-aggregated.yaml` in the remaining. You can change this profile with the variable **metrics_profile**.

**Note**: Metrics collection and indexing is enabled when setting prometheus `prom_url`

## Pin to server and tolerations

It's possible to pin kube-burner pod to a certain node using the `pin_server` parameter. This parameter is used in the job template as:

```jinja
{% if workload_args.pin_server is defined %}
{% for label, value in  workload_args.pin_server.items() %}
      {{ label | replace ("_", "-" )}}: {{ value }}
{% endfor %}
{% else %}
      node-role.kubernetes.io/worker: ""
{% endif %}
```

That is to say, by default kube-burner runs in worker nodes.  With the above we could configure the workload to run in infra labeled nodes with:

```yaml
workload:
  args:
    pin_server: {"node-role.kubernetes.io/infra": ""}
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


## Using a remote configuration for kube-burner

Apart from the pre-defined workloads available in `benchmark-operator`. it's possible to make kube-burner to fetch a remote configuration file, from
a remote http server. This mechanism can be used by pointing the variable `remote_config` to the desired remote configuration file:


```yaml
workload:
  args:
    remote_config: https://your.domain.org/kube-burner-config.yaml
```

Keep in mind that the object templated declared in this remote configuration file need to be pointed to a remote source as well so that kube-burner will also be able to fetch them. i.e
```yaml
    objects:
    - objectTemplate: https://your.domain.org/templates/pod.yml
      replicas: 1
```

> `kube-burner` is able to use go template based configuration files, in addition to the default behaviour, this template can reference environment variables using the syntax `{{ .MY_ENV_VAR }}`. The kube-burner job created by `benchmark-operator` always injects a list of environment variables which can be defined with the parameter `extra_env_vars` mentioned previously. This can be useful to parametrize remote configuration files as shown in the code snippet below.

Supossing a CR with `extra_env_vars` configured as:
```yaml
workload:
  args:
    extra_env_vars:
      INDEXING: true
      ES_SERVER: https://example-es.instance.com:9200
```

```yaml
global:
  writeToFile: false
  indexerConfig:
    enabled: {{.INDEXING}}
    esServers: ["{{.ES_SERVER}}"]
    insecureSkipVerify: true
    defaultIndex: ripsaw-kube-burner
    type: elastic
```


In addition to using remote configurations for kube-burner, it's also possible to use a remote metrics profile. It can be configured with the variable `remote_metrics_profile`

```yaml
workload:
  args:
    remote_metrics_profile: https://your.domain.org/metrics-profile.yaml
```

## Alerting

Kube-burner includes an alerting mechanism able to evaluate Prometheus expressions at the end of the latest Kube-burner's job. This alerting mechanism is based on a configuration file known as `alert-profile`. Similar to other configuration files. We can make usage of this feature in this Ripsaw's integration. Similar to other configuration files, this alert-profile can also be fetched from a remote location, this time configured by the variable `remote_alert_profile`.

```yaml
workload:
  args:
    remote_alert_profile: https://your.domain.org/alerting-profile.yaml
```

And this file looks like:

```yaml
# etcd alarms

- expr: avg_over_time(histogram_quantile(0.99, rate(etcd_disk_wal_fsync_duration_seconds_bucket[2m]))[5m:]) > 0.015
  description: 5 minutes avg. etcd fsync latency on {{$labels.pod}} higher than 15ms {{$value}}
  severity: error

- expr: avg_over_time(histogram_quantile(0.99, rate(etcd_network_peer_round_trip_time_seconds_bucket[5m]))[5m:]) > 0.1
  description: 5 minutes avg. etcd netowrk peer round trip on {{$labels.pod}} higher than 100ms {{$value}}
  severity: error

- expr: increase(etcd_server_leader_changes_seen_total[2m]) > 0
  description: etcd leader changes observed
  severity: error
```
Where expr holds the Prometheus expression to evaluate and description holds a description of the alert. 
It supports different severities:
- info: Prints an info message with the alarm description to stdout. By default all expressions have this severity.
- warning: Prints a warning message with the alarm description to stdout.
- error: Prints a error message with the alarm description to stdout and makes kube-burner rc = 1
- critical: Prints a fatal message with the alarm description to stdout and exits execution inmediatly with rc != 0

More information can be found at the [Kube-burner docs site.](https://kube-burner.readthedocs.io/en/latest/alerting/)

## Reading configuration from a configmap

Kube-burner is able to fetch it's own configuration from a configmap. To do so you just have to set the argument `configmap` pointing to a configmap in the same namespace where kube-burner is in the CR. This configmap needs to have a config.yml file to hold the main kube-burner's configuration file(apart from the required object templates), and optionally can contain a metrics.yml and alerts.yml files. An example configuration CR would look like:

```yaml
---
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: kube-burner-configmap-cfg
  namespace: benchmark-operator
spec:
  metadata:
    collection: false
  prometheus:
    prom_token: ThisIsNotAValidToken
    prom_url: https://prometheus-k8s.openshift-monitoring.svc.cluster.local:9091
  workload:
    name: kube-burner
    args:
      configmap: kube-burner-config
      cleanup: true
      pin_server: {"node-role.kubernetes.io/worker": ""}
      image: quay.io/cloud-bulldozer/kube-burner:latest
      log_level: info
      step: 30s
      node_selector:
        key: node-role.kubernetes.io/worker
        value:
      tolerations:
      - key: node-role.kubernetes.io/master
        effect: NoSchedule
```

To create a configmap with the kube-burner configurations you can use `kubectl create configmap --from-file=<directory with all configuration files> kube-burner-config`

