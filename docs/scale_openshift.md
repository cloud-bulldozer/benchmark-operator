# Scale Openshift

## What does it do?

The Scale Openshift functionality allows a user to scale their environment to a provided size 
and obtain the time it takes for the scaling procedure. This data will also be indexed if 
Elasticsearch information is provided.

## Variables

The scale workload takes the following required variables:

`scale` the target number of workers to scale to.

`serviceaccount` the service account to run as. Note the "default" account generally does not have enough privileges

Optional variables:

`poll_interval` how long, in seconds, to wait between polls to see if the scaling is complete. default: 5

`post_sleep` how long, in seconds, to wait after the scaling is complete before marking the pod as complete. default: 0

`label` a dictionary consisting of 'key' and 'value'. If provided it will require to launch the node with
        matching key and value

`tolerations` a dictionary consisting of a 'key', 'value' and 'effect'. If provided it will add a toleration
        for the matching key/value/effect

`runtime_class` If this is set, the benchmark-operator will apply the runtime_class to the podSpec runtimeClassName.

Your resource file may look like this when using all avaible options:

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: scale
  namespace: benchmark-operator
spec:
  elasticsearch:
    url: "http://es-instance.com:9200"
    index_name: ripsaw-scale
  workload:
    name: scale_openshift
    args:
      scale: 25
      serviceaccount: scaler
      poll_interval: 2
      post_sleep: 300
      label:
        key: node-role.kubernetes.io/workload
        value: ""
      tolerations:
        key: role
        value: workload
        effect: NoSchedule
```

*NOTE:* If the cluster is already at the desired scale the timings will still be captured and uploaded to
Elasticsearch (if provided). The overall time will simply be the time it took the scale process to confirm
that the cluster is at the correct scale.

## Service Account and Permissions

The default service account generally does not have the required visibility/permissions to allow the Scale job
to modify the cluster machine sets. An example service account setup has been provided in resources/scale_role.yaml
as well as described below:

```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: scale_role
rules:
- apiGroups:
  - "*"
  resources:
  - machines
  - machinesets
  - nodes
  - infrastructures
  verbs:
  - '*'
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: scaler
  namespace: benchmark-operator
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: scaler
  namespace: benchmark-operator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: scale_role
subjects:
- kind: ServiceAccount
  name: scaler
  namespace: benchmark-operator
```
