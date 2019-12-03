# Metadata Collection

How To:
* [How it Works](#how-it-works)
* [Enable Collection](#enable-collection)
* [Additional Options](#additional-options)
* [Running Additional Collections](#running-additional-collections)

# How it Works

The metadata collection is done through the use of [Stockpile](https://github.com/cloud-bulldozer/stockpile), [Backpack](https://github.com/cloud-bulldozer/backpack) and [Scribe](https://github.com/cloud-bulldozer/scribe).
The data is then uploaded to a defined Elasticsearch instance.

When launching your benchmark, if enabled, the metadata collection container (backpack)
will launch as a DaemonSet on all nodes in the cluster. It will then run stockpile
to gather data and then push that information up to Elasticsearch.

It runs the data collection/upload immediately upon launch and will not enter "Ready"
state until the initial data collection/upload has completed. Once this is done,
your benchmark will then launch and continue as normal. 

NOTE: The backpack pods will not complete/terminate until you delete your benchmark.
This is done to allow additional collections to be done as an ad-hoc basis as well.

# Enable Collection

By default metadata collection is turned off. 
To enable collection:

- Open the benchmark yaml that you will be running (for example byowl below)
```
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: byowl-benchmark
  namespace: my-ripsaw
spec:
  workload:
    name: byowl
    args:
      image: "quay.io/jtaleric/uperf:testing"
      clients: 1
      commands: "echo Test"
```

- Add ```metadata_collection: true``` to the spec section of the yaml
```
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: byowl-benchmark
  namespace: my-ripsaw
spec:
  metadata_collection: true
  workload:
    name: byowl
    args:
      image: "quay.io/jtaleric/uperf:testing"
      clients: 1
      commands: "echo Test"
```

The metadata collection will now be enabled however as there is no Elasticsearch information
defined it will fail.

- Add the Elasticsearch server and Port information
```
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: byowl-benchmark
  namespace: my-ripsaw
spec:
  elasticsearch:
    server: "my.elastic.server.foo"
    port: 9200
  metadata_collection: true
  workload:
    name: byowl
    args:
      image: "quay.io/jtaleric/uperf:testing"
      clients: 1
      commands: "echo Test"
```

The metadata collection will now run as described previously and continue to
the defined benchmark.

# Additional Options

There are a few additional options that can be enabled to enahnce the amount
of data collected.

## Privleged Pods

By default, pods are run in an unprivledged state. While this makes permissions
a lesser issue, it does limit the amount of data collected. For example, dmidecode
requires privledges to read the memory information and generate the data.

To enable privleged pods set:
```
metadata_privledged: true
```

In the spec section of the benchmark yaml as outlined for the other variables.

## Additional k8s Information

There are multiple kubernetes (k8s) based modules that are run in stockpile.
These modules are not accessable by default as the default service account
that runs the pod does not have the required privileges to view them. 

To allow the Daemon Set's pods view permissions on the cluster you can apply
the following yaml to create a service account with the appropriate 
privileges.

You will need to change the name and operator namespace to fit with your environment
Note: You can also find this yaml in resources/backpack_role.yaml

```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: backpack_role
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  - endpoints
  - persistentvolumeclaims
  - pods
  - replicationcontrollers
  - replicationcontrollers/scale
  - serviceaccounts
  - services
  - nodes
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - bindings
  - events
  - limitranges
  - namespaces/status
  - pods/log
  - pods/status
  - replicationcontrollers/status
  - resourcequotas
  - resourcequotas/status
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - namespaces
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - controllerrevisions
  - daemonsets
  - deployments
  - deployments/scale
  - replicasets
  - replicasets/scale
  - statefulsets
  - statefulsets/scale
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - autoscaling
  resources:
  - horizontalpodautoscalers
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - batch
  resources:
  - cronjobs
  - jobs
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - daemonsets
  - deployments
  - deployments/scale
  - ingresses
  - networkpolicies
  - replicasets
  - replicasets/scale
  - replicationcontrollers/scale
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - policy
  resources:
  - poddisruptionbudgets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - networking.k8s.io
  resources:
  - ingresses
  - networkpolicies
  verbs:
  - get
  - list
  - watch
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backpack-view
  namespace: my-ripsaw
---
apiVersion: v1
kind: Secret
metadata:
  name: backpack-view
  namespace: my-ripsaw
  annotations:
    kubernetes.io/service-account.name: backpack-view
type: kubernetes.io/service-account-token
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: backpack-view
  namespace: my-ripsaw
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: backpack_role
subjects:
- kind: ServiceAccount
  name: backpack-view
  namespace: my-ripsaw
```

# Running Additional Collections

While upon initial creation metadata is collected, it may be useful to collect
additional runs of data at other times. To do this you will need to loop through
each backpack Pod and exec the python command below:
```
python3 stockpile-wrapper.py -s [es_server] -p [es_port] -u [uuid]
```
Where es_server and es_port and the Elasticsearch server and port to index to.
The UUID can be any uuid string you would like (if you do not supply one it
will create one for you and you will see it defined in the output). On the
initial run at boot this is the same UUID as the benchmark UUID.
