# Kube-burner

## What is kube-burner?

kube-burner is a tool that allows a user to perform scalability tests across Kubernetes and OpenShift clusters by creating thousands of objects. Kube-burner is developed in it's own repository at https://github.com/cloud-bulldozer/kube-burner
This ripsaw integration is meant to run certain workloads useful to measure certain performance KPIs of a cluster.

## Running kube-burner

Given that you followed instructions to deploy operator. Kube-burner needs an additional serviceaccount and clusterrole to run. Available at [kube-burner-role.yml](../resources/kube-burner-role.yml)
You can modify kube-burner's [cr.yaml](../resources/crds/ripsaw_v1alpha1_kube-burner_cr.yaml) to fit your requirements.

## Supported workloads

Ripsaw's kube-burner integration supports the following workloads:

- **cluster-density**: This workload is a cluster density focused test that creates a set of Deployments, Builds, Secret, Services and Routes across the cluster. This is a namespaced workload, meaning that kube-burner **will create as many namespaces with these objects as the configured job_iterations**. 

**Note**: This workload uses the kube-burner's parameter _*waitFor: ["Deployment"]*_ in order to wait only for deployments in case of using `wait_when_finished`
- **kubelet-density**: Creates a single namespace with a number of Deployments equal to **job_iterations**
- **kubelet-density-heavy**. Creates a **single namespace with a number of applications equals to job_iterations**. This application consists on two deployments (a postgresql database and a simple client that generates some CPU load) and a service that is used by the client to reach the database.

The workload is specified by the parameter `workload` from the `args` object of the configuration.

## Configuration

All kube-burner's workloads support the following parameters:

- workload: Type of kube-burner workload. As mentioned before, allowed values are cluster-density, kubelet-density and kubelet-density-heavy
- default_index: Elasticsearch index name. Defaults to __ripsaw-kube-burner__
- job_iterations: How many iterations to execute of the specified kube-burner workload
- qps: Limit object creation queries per second. Defaults to __5__
- burst: Maximum burst for throttle. Defaults to __10__
- image: Allows to use an alternative kube-burner container image. Defaults to `quay.io/cloud-bulldozer/kube-burner:latest`
- wait_when_finished: Makes kube-burner to wait for all objects created to be ready/completed before index metrics and finishing the job. Defaults to __true__
- pod_wait: Wait for all pods to be running before moving forward to the next job iteration. Defaults to __false__
- verify_objects: Verify object count after running each job. Defaults to __true__
- error_on_verify: Exit with rc 1 before indexing when object verification fails. Defaults to __false__
- log_level: Kube-burner log level. Allowed info and debug. Defaults to __info__
- node_selector: Pods deployed by the different workloads use this nodeSelector. This parameter consists of a dictionary like:

```yaml
node_selector:
  value: node-role.kubernetes.io/master
  key: ""
```
Where value defaults to __node-role.kubernetes.io/worker__ and key defaults to empty string ""

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

Metrics collected by kube-burner are predefined in the [metrics.yaml file](../roles/kube-burner/files/metrics.yaml)

## Pin to server

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
    workload: kubelet-density
    job_iterations: 100
    pin_server: ip-10-0-176-173
```

