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
# oc create -f deploy/service_account.yaml
# oc create -f deploy/crd/bench_v1alpha1_bench_crd.yaml
# oc create -f deploy/operator.yaml
```

At this point, you can modify `deploy/crd/bench_v1alpha1_bench_cr.yaml

```yaml
apiVersion: bench.example.com/v1alpha1
kind: Bench
metadata:
  name: example-bench
spec:
  uperf:
    # Server size must always be 1 or more
    pairs: 1
    proto: tcp
    test_type: stream
    nthr: 2
    size: 16384
    runtime: 60
```

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
