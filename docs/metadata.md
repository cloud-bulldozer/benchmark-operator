# Metadata Collection

How To:
- [Metadata Collection](#metadata-collection)
  - [How it Works](#how-it-works)
  - [Targeted Init Containers](#targeted-init-containers)
  - [DaemonSet](#daemonset)
  - [Differences between targeted and daemonset](#differences-between-targeted-and-daemonset)
- [Enable Collection](#enable-collection)
  - [Additional Options](#additional-options)
    - [Customizing backpack image](#customizing-backpack-image)
    - [Privileged Pods](#privileged-pods)
    - [Additional k8s Information](#additional-k8s-information)
    - [Stockpile tags](#stockpile-tags)
    - [Redis integration](#redis-integration)
  - [Running Additional Collections](#running-additional-collections)

## How it Works

The metadata collection is done through the use of [Stockpile](https://github.com/cloud-bulldozer/stockpile), [Backpack](https://github.com/cloud-bulldozer/backpack) and [Scribe](https://github.com/cloud-bulldozer/scribe).
The data is then uploaded to a defined Elasticsearch instance.

Metadata collection is enabled by default, it can be disabled setting collection to false in the metadata section:

```yaml
metadata:
  collection: false
```

There are two ways to launch metadata collection from a workload.

## Targeted Init Containers

The first, and default behavior, is through init containers. These are defined in
the workload template with an init container section that looks like:

```jinja
{% if metadata.collection is sameas true and metadata.targeted is sameas true %}
{% if metadata.serviceaccount != "default" %}
      serviceAccountName: {{ metadata.serviceaccount }}
{% endif %}
      initContainers:
      - name: backpack-{{ trunc_uuid }}
        image: {{ metadata.image }}
        command: ["/bin/sh", "-c"]
        args:
          - >
            python3
            stockpile-wrapper.py
            -s={{ elasticsearch.url }}
            -u={{ uuid }}
            -n=${my_node_name}
            -N=${my_pod_name}
            --redisip={{ bo.resources[0].status.podIP }}
            --redisport=6379
{% if metadata.force is sameas true %}
            --force
{% endif %}
{% if metadata.stockpileTags|length > 0 %}
            --tags={{ metadata.stockpileTags|join(",") }}
{% endif %}
{% if metadata.stockpileSkipTags|length > 0 %}
            --skip-tags={{ metadata.stockpileSkipTags|join(",") }}
{% endif %}
{% if metadata.ssl is sameas true %}
            --sslskipverify
{% endif %}
        imagePullPolicy: Always
        securityContext:
          privileged: {{ metadata.privileged }}
        env:
          - name: my_node_name
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: my_pod_name
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
{% endif %}
```

This allows the targeted collection of metadata on nodes that only have workloads on
them. This avoids trying to collect data from nodes we are not touching. The backpack
container will run stockpile to gather data and then push that information into
Elasticsearch. Once complete the init container will terminate and the workload will 
launch and continue as normal.

## DaemonSet

If it is desired to run the metadata collection in the "classic" way (i.e. as a DaemonSet),
then you will need to set ```metadata.targeted: false``` in your cr file.

When configured in this way, backpack will launch as a DaemonSet on all nodes in 
the cluster when the workload is applied. Backpack will then run stockpile to gather
 data and then push that information up to Elasticsearch exactly like the targeted/init
 container option.

It runs the data collection/upload immediately upon launch and will not enter "Ready"
state until the initial data collection/upload has completed. Once this is done,
your benchmark will then launch and continue as normal. 

The DaemonSet option is able to take another optional parameters that the targeted 
variant cannot. You are able to supply a list of label/value pairs in label. This 
will have the DaemonSet only run on nodes that match any of the labels provided. 

In the below example the metadata DaemonSet will only run on nodes labeled with foo=bar 
OR awesome=sauce. It can match either provided label.

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: byowl-benchmark
  namespace: benchmark-operator
spec:
  elasticsearch:
    url: "http://my.elastic.server.foo:9200"
  metadata:
    collection: true
    targeted: false
    label:
      - [ 'foo', 'bar' ]
      - [ 'awesome', 'sauce' ]
  workload:
    name: byowl
    args:
      image: "quay.io/jtaleric/uperf:testing"
      clients: 1
      commands: "echo Test"
```

## Differences between targeted and daemonset

There are a few notable differences between the DaemonSet and targeted options:

- First, and most important, the DaemonSet will run on ALL nodes of the cluster.
This means that if you have 200 nodes it will collect data from all the nodes
even if your relevant pod(s) are only running on a subset of nodes. You will end
up with more data than you need and slow down the start of your workload.

- If running targeted and with a service account (more on that below) the
entire workload will run as that service account. That is because service accounts
are done at a level above the container definition and can only be applied once.

- When run as a daemonset the backpack pods will not complete/terminate 
until you delete your benchmark. This is done to allow additional collections to 
be done as an ad-hoc basis as well.

- When running as a targeted init container the benchmark metadata status will be
set to "Collecting" however it will never be marked as completed as that would require
additional logic in the workloads which is out of scope.

- Finally, running as a daemonset requires no additions to the workload
template. This may be preferable in certain situations.

# Enable Collection

By default metadata collection is turned off. 
To enable collection:

- Open the benchmark yaml that you will be running (for example byowl below)
```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: byowl-benchmark
  namespace: benchmark-operator
spec:
  workload:
    name: byowl
    args:
      image: "quay.io/jtaleric/uperf:testing"
      clients: 1
      commands: "echo Test"
```

- Add ```metadata.collection: true``` to the spec section of the yaml
```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: byowl-benchmark
  namespace: benchmark-operator
spec:
  metadata:
    collection: true
  workload:
    name: byowl
    args:
      image: "quay.io/jtaleric/uperf:testing"
      clients: 1
      commands: "echo Test"
```

The metadata collection will now be enabled however as there is no Elasticsearch information
defined it will fail.

- Add the Elasticsearch server information
```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: byowl-benchmark
  namespace: benchmark-operator
spec:
  elasticsearch:
    url: "http://my.elastic.server.foo:9200"
  metadata:
    collection: true
  workload:
    name: byowl
    args:
      image: "quay.io/jtaleric/uperf:testing"
      clients: 1
      commands: "echo Test"
```

The metadata collection will now run as defined.

## Additional Options

There are a few additional options that can be enabled to enhance the amount
of data collected as well as reduce redundancy.


### Customizing backpack image

By default backpack uses `quay.io/cloud-bulldozer/backpack:latest`, however it's possible to customize this image 
setting the image parameter from the metadata section:

```yaml
metadata:
  image: quay.io/myorg/custom-backpack:latest
```

### Privileged Pods

By default, pods are run in an unprivledged state. While this makes permissions
a lesser issue, it does limit the amount of data collected. For example, dmidecode
requires privileges to read the memory information and generate the data.

To enable privileged pods set:

```yaml
metadata:
  privileged: true
```

In the spec section of the benchmark yaml as outlined for the other variables.

### Elasticsearch SSL Verification

By default elasticsearch SSL verification is disabled. To enable it, set ssl
to true in the metadata section.

To enable ssl verification:

```yaml
metadata:
  ssl: true
```

### Additional k8s Information

There are multiple kubernetes (k8s) based modules that are run in stockpile.
These modules are not accessable by default as the default service account
that runs the pod does not have the required privileges to view them. 

To allow the pods view permissions on the cluster you can apply
the following yaml to create a service account with the appropriate 
privileges.

You will need to change the namespace to fit with your environment
Note: You can also find this yaml in [backpack_role.yaml](../resources/backpack_role.yaml)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: backpack_role
rules:
- apiGroups:
  - "*"
  resources:
  - "*"
  verbs:
  - get
  - list
  - watch
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backpack-view
  namespace: benchmark-operator
---
apiVersion: v1
kind: Secret
metadata:
  name: backpack-view
  namespace: benchmark-operator
  annotations:
    kubernetes.io/service-account.name: backpack-view
type: kubernetes.io/service-account-token
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: backpack-view
  namespace: benchmark-operator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: backpack_role
subjects:
- kind: ServiceAccount
  name: backpack-view
  namespace: benchmark-operator
```

Once the `backpack-view` service account is created you can modify the default backpack service account setting:

```yaml
metadata:
  serviceaccount: backpack-view
```

### Stockpile tags

Backpack leverages [stockpile](https://github.com/cloud-bulldozer/stockpile/) to collect metadata. Stockpile is basically a set of Ansible roles, these roles have different tags. It's possible to pass custom tags to the inner `ansible-playbook` command through the parameters `stockpileSkipTags` and `stockpileTags` from the metadata section. These parameters are translated to the Ansible's flags _--tags_ and _--skip-tags_ respectively.
By default `stockpileTags` has the value `["common", "k8s", "openshift"]`.

An example to only collect metadata from the roles tagged with memory and cpu would be:

```yaml
metadata:
  stockpileTags: ["memory", "cpu"]
```

An example to skip these tags would be:
```yaml
metadata:
  stockpileSkipTags: ["memory", "cpu"]
```


### Redis integration

When the stockpile-wrapper.py script is passed --redisip [ip of redis] and --redisport [redis port]
it will attempt to check Redis to see if the host has had its metadata collected for the current uuid.
If it has already been collected we will not run the collection again. This will reduce some redundant
data that was being collected when pods were launched on the same node.

If it is desired to run the metadata collection regardless of if Redis claims it was already run then
passing the script the --force option will force the metadata collection to occur.

*NOTE* As Redis integration is already configured for the existing workloads nothing needs to be
done to enable it. However, if you wish to use the --force option you will need to add ```force: true```
to the metadata section of your workload cr file.

```yaml
metadata:
  force: true
```

## Running Additional Collections

*NOTE* This is only applicable to the DaemonSet collection method

While upon initial creation metadata is collected, it may be useful to collect
additional runs of data at other times. To do this you will need to loop through
each backpack Pod and exec the python command below:
```
python3 stockpile-wrapper.py -s [es_url] -u [uuid]
```
Where es_url points to the Elasticsearch server to index to.
The UUID can be any uuid string you would like (if you do not supply one it
will create one for you and you will see it defined in the output). On the
initial run at boot this is the same UUID as the benchmark UUID.
