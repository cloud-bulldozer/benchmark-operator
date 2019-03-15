# Benchmark Operator

The intent of this Operator is to deploy common workloads to establish
a performance baseline of your provider.

## Workloads
| Workload | Use?                | Status in Operator |
| -------- | --------------------| ------------------ |
| UPerf                | Network Performance | Working            |
| FIO                  | Storage IO          | Working            |
| Couchbase + YCSB     | Databse Performance | WIP            |


## How to use?
```bash
# git clone https://github.com/jtaleric/benchmark-operator
# cd benchmark-operator
# export KUBECONFIG=<your_kube_config>
# oc new-project benchmark
# oc project benchmark
# oc create -f deploy/role.yaml
# oc create -f deploy/role_binding.yaml
# oc create -f deploy/cluster_role.yaml
# oc create -f deploy/cluster_role_binding.yaml
# oc create -f deploy/service_account.yaml
# oc create -f deploy/crd/bench_v1alpha1_bench_crd.yaml
# oc create -f deploy/operator.yaml
```

OpenShift prior to v 4.0 and $some k8s deployments may also need the `cluster-admin` ClusterRole in order to run some workloads that are themselves operator-controlled and therefore require special access to the cluster.

```bash
# oc create -f deploy/cluster_admin_role_binding.yaml
```

At this point, you can modify `deploy/crd/bench_v1alpha1_bench_cr.yaml

```yaml
apiVersion: bench.example.com/v1alpha1
kind: Bench
metadata:
  name: example-bench
spec:
  uperf:
    # To disable uperf, set pairs to 0
    pair: 0
    proto: tcp
    test_type: stream
    nthr: 2
    size: 16384
    runtime: 10
  couchbase:
    # To disable couchbase, set servers.size to 0
    # Typical deployment size is 3
    servers:
      size: 0
    storage:
      use_persistent_storage: false
      class_name: "rook-ceph-block"
      volume_size: 10Gi
    on_openshift: True
    rh_pull_secret: <Insert Pull secret from Red Hat Registry>
  fio:
    # To disable fio, set clients to 0
    clients: 0
    jobname: test-write
    bs: 4k
    iodepth: 4
    runtime: 57
    rw: write
    filesize: 1
```

> **Running Couchbase on OpenShift**
> 
> The upstream couchbase container images will not run properly on OpenShift. You will need to pull images from the Red Hat Container Catalog. The Red Hat images will automatically be selected via the `roles/couchbase-infra/templates/couchbase-cluster.yaml.j2` template when `spec.couchbase.on_openshift` is set to `true` in the CR file as above.
> 
> Pulling these images requires a valid `.dockerconfigjson` secret, which you can get from the Red Hat Container Catalog [registry.redhat.io](registry.redhat.io) after you have authenticated by clicking on *Service Accounts*, then on the appropriate *Account name*, then on the *OpenShift Secret* tab. From there, you can download or view the \<username\>-secret.yaml file. Copy the string from `data..dockerconfigjson` in the secret file and paste it into the `spec.couchbase.rh_pull_secret` field in the CR as above.


Deploying the above will result in :
```
NAME                                                READY     STATUS    RESTARTS   AGE       IP             NODE                                         NOMINATED NODE
benchmark-operator-6ff5bf5db8-nzvl8                 1/1       Running   0          2m12s     10.129.2.186   ip-10-0-152-138.us-west-2.compute.internal   <none>
example-bench-uperf-client-bench-7f8fb9bc8-q2xbx    1/1       Running   0          101s      10.129.2.188   ip-10-0-152-138.us-west-2.compute.internal   <none>
example-bench-uperf-server-bench-68779b4986-nz5w8   1/1       Running   0          117s      10.129.2.187   ip-10-0-152-138.us-west-2.compute.internal   <none>
```

The first pod is our Operator orchestrating the UPerf workload.

To review the results, `oc logs <client>`, the top of the output is
the actual workload that was passed to UPerf (From the values in the custom resource)

```
<?xml version=1.0?>
<profile name="tcp-stream-16384B-2i">
<group nthreads="2">
      <transaction iterations="1">
        <flowop type="connect" options="remotehost=$h protocol=tcp"/>
      </transaction>
      <transaction duration="60">
        <flowop type=write options="count=16 size=16384"/>
      </transaction>
      <transaction iterations="1">
        <flowop type=disconnect />
      </transaction>
  </group>
</profile>
Starting 2 threads running profile:tcp-stream-16384b-2i ...   0.00 seconds
Txn1          0 /   0.00(s) =            0           0op/s
Txn1          0 /   1.00(s) =            0           2op/s

Txn2          0 /   0.00(s) =            0           0op/s
Txn2     1.23GB /   1.02(s) =    10.30Gb/s       78563op/s
Txn2     2.22GB /   2.03(s) =     9.39Gb/s       71623op/s
Txn2     3.06GB /   3.09(s) =     8.51Gb/s       64889op/s
Txn2     4.17GB /   4.09(s) =     8.75Gb/s       66770op/s
Txn2     4.92GB /   5.20(s) =     8.12Gb/s       61941op/s
Txn2     5.17GB /   6.21(s) =     7.16Gb/s       54644op/s
Txn2     5.71GB /   7.21(s) =     6.81Gb/s       51957op/s
Txn2     6.57GB /   8.21(s) =     6.87Gb/s       52436op/s
Txn2     7.43GB /   9.22(s) =     6.93Gb/s       52851op/s
Txn2     8.40GB /  10.22(s) =     7.06Gb/s       53896op/s
Txn2     9.46GB /  11.22(s) =     7.24Gb/s       55239op/s

... Trimmed ...

Txn2    54.98GB /  56.48(s) =     8.36Gb/s       63798op/s
Txn2    55.72GB /  57.48(s) =     8.33Gb/s       63524op/s
Txn2    56.34GB /  58.49(s) =     8.27Gb/s       63117op/s
Txn2    57.26GB /  59.70(s) =     8.24Gb/s       62863op/s

Txn3          0 /   0.00(s) =            0           0op/s
Txn3          0 /   0.00(s) =            0           0op/s

-------------------------------------------------------------------------------
Total   57.26GB /  61.80(s) =     7.96Gb/s       60722op/s

Netstat statistics for this run
-------------------------------------------------------------------------------
Nic       opkts/s     ipkts/s      obits/s      ibits/s
eth0        47663        2575     7.98Gb/s     1.37Mb/s
-------------------------------------------------------------------------------

Run Statistics
Hostname            Time       Data   Throughput   Operations      Errors
-------------------------------------------------------------------------------
10.129.2.187      61.80s    57.26GB     7.96Gb/s      3752501        0.00
master            61.80s    57.26GB     7.96Gb/s      3752900        0.00
-------------------------------------------------------------------------------
Difference(%)     -0.00%      0.01%        0.01%        0.01%       0.00%
```
