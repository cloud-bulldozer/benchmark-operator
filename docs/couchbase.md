# Couchbase

[Couchbase](https://couchbase.com) is a NoSQL document-oriented database infrastructure

## Prerequisites
The [Operator Lifecycle Manager (OLM)](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Documentation/install/install.md) is required to run the Couchbase operator from [operatorhub.io](https://operatorhub.io). If your distribution of OpenShif/Kubernetes does not include this, you will need to install it first.

*Note: As of this writing, deploying the OLM from the deployment directory documented in the link above may lead to the Couchbase operator failing to launch. You may need to deploy instead from the `upstream/quickstart/olm.yaml` file as in:*

```bash
$ kubectl create -f https://raw.githubusercontent.com/operator-framework/operator-lifecycle-manager/master/deploy/upstream/quickstart/olm.yaml
```

## Running the Couchbase infra

Given that you followed instructions to deploy the benchmark operator,
you can modify the [cr.yaml](../deploy/crds/bench_v1alpha1_bench_cr.yaml)

Note: Set other roles to 0 to disable them when editing the
[cr.yaml](../deploy/crds/bench_v1alpha1_bench_cr.yaml) file, or create 
your own custom resource file with only the roles you want defined. An 
example to enable only Couchbase:

```yaml
apiVersion: bench.example.com/v1alpha1
kind: Bench
metadata:
  name: example-bench
spec:
  couchbase:
    # To disable couchbase, set servers.size to 0
    # Typical deployment size is 3
    servers:
      size: 3
    storage:
      use_persistent_storage: True
      class_name: "rook-ceph-block"
      volume_size: 10Gi
    on_openshift: True
    rh_pull_secret: <your registry.redhat.io pull secret>
```

If you set `spec.couchbase.stroage.use_persistent_storage` to `true`, then you will need to provide a valid 
StorageClass name for `spec.couchbase.storage.class_name` and a valid volume size for `spec.couchbase.storage.volume_size`. 
Setting up a StorageClass is outside the scope of this documentation.

Note that the upstream couchbase container images will not run on OpenShift as of this build, 
therefore logic is included in the role to pull from [registry.redhat.io](https://registry.redhat.io)
in the case that `spec.couchbase.on_openshift` is set to `true` in the CR.

You will need to add your Red Hat registry secret to your OpenShift deployment before deploying the
couchbase infra. To get your Red Hat registry secret, navigate to [registry.redhat.io](https://registry.redhat.io) and 
login. Then click on the **Service Accounts** button, the on your appropriate account name, then on the 
**OpenShift Secret** tab. From there, download or view the \<username\>.secret.yaml file, and 
add the secret to your deployment:

```bash
# oc create -f \<username\>.secret.yaml
```

Once you are finished creating/editing the custom resource file, you can run it by:

```bash
# kubectl create -f /path/to/bench_v1alpha1_bench_cr.yaml
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

```bash
$ kubectl describe cbc
Name:         cb-benchmark
Namespace:    benchmark
Labels:       <none>
Annotations:  <none>
API Version:  couchbase.com/v1
Kind:         CouchbaseCluster
Metadata:
  Creation Timestamp:  2019-03-21T21:32:45Z
  Generation:          1
  Owner References:
    API Version:     bench.example.com/v1alpha1
    Kind:            Bench
    Name:            example-bench
    UID:             c87f2ba3-4c20-11e9-8a78-128d7ee91aa6
  Resource Version:  2201864
  Self Link:         /apis/couchbase.com/v1/namespaces/benchmark/couchbaseclusters/cb-benchmark
  UID:               de05d9d5-4c20-11e9-b61f-0eb0f8a20cc0
Spec:
  Admin Console Services:
    data
  Auth Secret:  cb-example-auth
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

Note that the Couchbase role is only an infrastructure role, and no workloads will be triggered directly 
by running the CR as described here. You will need to separately define a workload in the CR (such as YCSB [work in progress]).

## Cleanup
Currently, the couchbase-operator deployment does not clean up on it's on when the
CR is deleted or changed to disable couchbase. You will need to do this manually with:

```bash
$ kubectl delete deployment couchbase-operator
```
