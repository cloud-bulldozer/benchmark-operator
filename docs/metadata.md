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
that runs the pod does not have the required privileges to access them. 

To allow the Daemon Set's pods view permissions on the cluster you can apply
the following yml files to create a service account with the appropriate 
privileges.

The following assumes setting the ```metadata_sa``` and ```operator_namespace``` variables.

Create the service account:

```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: "{{ metadata_sa }}"
  namespace: "{{ operator_namespace }}"
```

Create the secret token for the service account:

```
apiVersion: v1
kind: Secret
metadata:
  name: "{{ metadata_sa }}"
  namespace: "{{ operator_namespace }}"
  annotations:
    kubernetes.io/service-account.name: "{{ metadata_sa }}"
type: kubernetes.io/service-account-token
```

Create the Cluster Role Binding to allow the service account
View permissions on the cluster:

```
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: "{{ metadata_sa }}"
  namespace: "{{ operator_namespace }}"
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
- kind: ServiceAccount
  name: {{ metadata_sa }}
  namespace: {{ operator_namespace }}
```

Once created, define the ```metadata_sa``` variable in the spec section
along side the other metadata variables and apply your benchmark. Per 
our example:

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
  metadata_sa: backpack-view
  workload:
    name: byowl
    args:
      image: "quay.io/jtaleric/uperf:testing"
      clients: 1
      commands: "echo Test"
```

# Running Additional Collections

While upon initial creation metadata is collected, it may be useful to collect
additional runs of data at other times. To do this you will need to loop through
each backpack Pod and exec the python command below:
```
python3 stockpile-wrapper-always.py -s [es_server] -p [es_port] -u [uuid]
```
Where es_server and es_port and the Elasticsearch server and port to index to.
The UUID can be any uuid string you would like (if you do not supply one it
will create one for you and you will see it defined in the output). On the
initial run at boot this is the same UUID as the benchmark UUID.
