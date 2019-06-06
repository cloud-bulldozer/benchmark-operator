# Couchbase

[Couchbase](https://couchbase.com) is a NoSQL document-oriented database infrastructure

## Prerequisites
### OLM
The [Operator Lifecycle Manager (OLM)](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Documentation/install/install.md) is required to run the Couchbase operator from [operatorhub.io](https://operatorhub.io). If your distribution of OpenShift/Kubernetes does not include this, you will need to install it first.

> Note: As of this writing, deploying the OLM from the deployment directory documented in the link above may lead to the Couchbase operator failing to launch. You may need to deploy instead from the `upstream/quickstart/olm.yaml` file as in:

```bash
$ kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-lifecycle-manager/master/deploy/upstream/quickstart/olm.yaml
```
> Note: Sometimes applying OLM fails on first try, so please retry if it happens.

### Marketplace
In addition to the OLM, the deployment of the Couchbase infra expects to use the [Marketplace operator](https://github.com/operator-framework/operator-marketplace#installing-an-operator-using-marketplace). Again, if your distribution of OpenShift/Kubernetes does not include this, you will need to install it first.

Example:
```bash
$ git clone https://github.com/operator-framework/operator-marketplace.git
$ kubectl apply -f operator-marketplace/deploy/upstream
```

## Using the Couchbase Infra

### Customizing your CR

An example to enable only the Couchbase infra (this does _not_ run a workload):

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: couchbase-infra
  namespace: ripsaw
spec:
  infrastructure:
    name: couchbase
    args:
      servers:
        size: 3
      storage:
        use_persistent_storage: True
        class_name: "rook-ceph-block"
        volume_size: 10Gi
      deployment:
        catalogsource_namespace: "marketplace"
        cb_operator_package: "couchbase-enterprise"
        pod_base_image: "docker.io/library/couchbase"
        pod_version: "enterprise-5.5.2"
        default_bucket_password: "password"
```

**Please see the example [CR file](../examples/infra/couchbase.yaml) for further examples for different deployment environments.**

### Persistent Storage
If you set `spec.infrastructure.args.stroage.use_persistent_storage` to `true`, then you will need to provide a valid
StorageClass name for `spec.infrastructure.args.storage.class_name` and a valid volume size for `spec.infrastructure.args.storage.volume_size`.

*Setting up a StorageClass is outside the scope of this documentation.*

### OpenShift Notes
Upstream couchbase images will not run correctly on OpenShift, so the images will need to be pulled from the Red Hat registry.

In order to pull images from the Red Hat registry, you will need to add a valid Red Hat registry
secret to your OpenShift deployment before deploying the couchbase infra. To get your registry
secret, navigate to [registry.redhat.io](https://registry.redhat.io) and login. Then click on the **Service Accounts**
button, then on your appropriate account name, then on the **OpenShift Secret** tab. From there,
download or view the \<username\>.secret.yaml file. Add this secret to your cluster in the _ripsaw_ namespace.

```
oc create -f <username>.secret.yaml -n ripsaw
```

> Note that the `metadata.name` value from the secret file will need to be used as the `spec.infrastructure.args.deployment.pull_secret_name` value in the CR.

Example CR for OpenShift v3:
```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: couchbase-infra
  namespace: ripsaw
spec:
  infrastructure:
    name: couchbase
    args:
      servers:
        size: 3
      storage:
        use_persistent_storage: True
        class_name: "rook-ceph-block"
        volume_size: 10Gi
      deployment:
        catalogsource_namespace: "marketplace"
        cb_operator_package: "couchbase-enterprise"
        pod_base_image: "registry.connect.redhat.com/couchbase/server"
        pod_version: "5.5.4-1"
        default_bucket_password: "password"
        pull_secret_name: "rhsecret"
```

Example CR for OpenShift v4 (which includes a built-in OLM and Marketplace):
```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: couchbase-infra
  namespace: ripsaw
spec:
  infrastructure:
    name: couchbase
    args:
      servers:
        size: 3
      storage:
        use_persistent_storage: True
        class_name: "rook-ceph-block"
        volume_size: 10Gi
      deployment:
        catalogsource_namespace: "openshift-marketplace"
        cb_operator_package: "couchbase-enterprise-certified"
        pod_base_image: "registry.connect.redhat.com/couchbase/server"
        pod_version: "5.5.4-1"
        default_bucket_password: "password"
        pull_secret_name: "rhsecret"
```

### Starting the Infra
Once you are finished creating/editing the custom resource file and the Ripsaw benchmark operator is running, you can start the infra with:

```bash
$ kubectl apply -f /path/to/cr.yaml
```

Deploying the above will first result in the Couchbase operator running (along with a catalog container).

```bash
$ kubectl get pods -l name=couchbase-operator
NAME                                  READY     STATUS    RESTARTS   AGE
couchbase-operator-7b489f685c-j6vs8   1/1       Running   0          4m59s
```

Once the Couchbase operator is running, the benchmark operator will then launch the couchbase
server infrastructure in a stateful manner.

```bash
$ kubectl get pods -l app=couchbase
NAME                READY     STATUS    RESTARTS   AGE
cb-benchmark-0000   1/1       Running   0          5m27s
cb-benchmark-0001   1/1       Running   0          4m52s
cb-benchmark-0002   1/1       Running   0          4m18s
```

You can then confirm the state of the couchbase cluster:

```
$ kubectl describe cbc
Name:         cb-benchmark
Namespace:    ripsaw
Labels:       <none>
Annotations:  <none>
API Version:  couchbase.com/v1
Kind:         CouchbaseCluster
Metadata:
  Creation Timestamp:  2019-03-21T21:32:45Z
  Generation:          1
  Owner References:
    API Version:     ripsaw.cloudbulldozer.io/v1alpha1
    Kind:            Benchmark
    Name:            example-benchmark
    UID:             c87f2ba3-4c20-11e9-8a78-128d7ee91aa6
  Resource Version:  2201864
  Self Link:         /apis/couchbase.com/v1/namespaces/benchmark/couchbaseclusters/cb-benchmark
  UID:               de05d9d5-4c20-11e9-b61f-0eb0f8a20cc0
Spec:
  Admin Console Services:
    data
  Auth Secret:  cb-cluster-auth
  Base Image:   registry.connect.redhat.com/couchbase/server
  Buckets:
    Conflict Resolution:  seqno
    Enable Flush:         true
    Eviction Policy:      fullEviction
    Io Priority:          high
    Memory Quota:         128
    Name:                 default
    Replicas:             1
    Type:                 couchbase
  Cluster:
    Analytics Service Memory Quota:                 1024
    Auto Failover Max Count:                        3
    Auto Failover On Data Disk Issues:              true
    Auto Failover On Data Disk Issues Time Period:  120
    Auto Failover Server Group:                     false
    Auto Failover Timeout:                          120
    Cluster Name:                                   cb-benchmark
    Data Service Memory Quota:                      256
    Eventing Service Memory Quota:                  256
    Index Service Memory Quota:                     256
    Index Storage Setting:                          memory_optimized
    Search Service Memory Quota:                    256
  Expose Admin Console:                             true
  Servers:
    Name:  all_services
    Pod:
      Resources:
      Volume Mounts:
        Data:     couchbase
        Default:  couchbase
    Services:
      data
      index
      query
      search
      eventing
      analytics
    Size:                         3
  Software Update Notifications:  false
  Version:                        5.5.2-2
  Volume Claim Templates:
    Metadata:
      Creation Timestamp:  <nil>
      Name:                couchbase
    Spec:
      Resources:
        Requests:
          Storage:         10Gi
      Storage Class Name:  rook-ceph-block
    Status:
Status:
  Admin Console Port:      30266
  Admin Console Port SSL:  32208
  Buckets:
    Default:
      Conflict Resolution:  seqno
      Enable Flush:         true
      Eviction Policy:      fullEviction
      Io Priority:          high
      Memory Quota:         128
      Name:                 default
      Replicas:             1
      Type:                 couchbase
  Cluster Id:               dba94554cb21febc013fbeb27b2528ff
  Conditions:
    Available:
      Last Transition Time:  2019-03-21T21:33:36Z
      Last Update Time:      2019-03-21T21:33:36Z
      Reason:                Cluster available
      Status:                True
    Balanced:
      Last Transition Time:  2019-03-21T21:35:28Z
      Last Update Time:      2019-03-21T21:35:28Z
      Message:               Data is equally distributed across all nodes in the cluster
      Reason:                Cluster is balanced
      Status:                True
  Control Paused:            false
  Current Version:           5.5.2-2
  Members:
    Index:  3
    Ready:
      Name:  cb-benchmark-0000
      Name:  cb-benchmark-0001
      Name:  cb-benchmark-0002
  Phase:     Running
  Reason:
  Size:      3
Events:
  Type    Reason              Age   From                                 Message
  ----    ------              ----  ----                                 -------
  Normal  ServiceCreated      3m    couchbase-operator-7b489f685c-ds88v  Service for admin console `cb-benchmark-ui` was created
  Normal  NewMemberAdded      2m    couchbase-operator-7b489f685c-ds88v  New member cb-benchmark-0000 added to cluster
  Normal  NewMemberAdded      1m    couchbase-operator-7b489f685c-ds88v  New member cb-benchmark-0001 added to cluster
  Normal  NewMemberAdded      1m    couchbase-operator-7b489f685c-ds88v  New member cb-benchmark-0002 added to cluster
  Normal  RebalanceStarted    1m    couchbase-operator-7b489f685c-ds88v  A rebalance has been started to balance data across the cluster
  Normal  RebalanceCompleted  36s   couchbase-operator-7b489f685c-ds88v  A rebalance has completed
  Normal  BucketCreated       26s   couchbase-operator-7b489f685c-ds88v  A new bucket `default` was created
```

> Note that the Couchbase role is only an infrastructure role, and no workloads will be triggered directly
by running the CR as described here. You will need to separately define a workload in the CR (such as [YCSB](ycsb.md)).

## Cleanup
Currently, the couchbase-operator deployment does not fully clean up on it's on when the
CR is deleted or changed to disable couchbase. You will need to do this manually with:

```bash
$ kubectl delete csv couchbase-operator.<version>
```
