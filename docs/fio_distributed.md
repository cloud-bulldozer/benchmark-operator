# FIO Distributed

FIO (Flexible I/O Tester) has a native mechanism to run multiple servers concurrently and summarize
the results.

This workload will launch N number of FIO Servers and a single FIO Client which will kick off the
workload.

## Running Distributed FIO

Build your CR for Distributed FIO

```yaml
apiVersion: benchmark.example.com/v1alpha1
kind: Benchmark
metadata:
  name: fio-benchmark
  namespace: ripsaw
spec:
  workload:
    name: "fio_distributed"
    args:
      servers: 1
      pin: false
      pin_server: "master-0"
      job: seq
      jobname: seq
      bs: 64k
      iodepth: 4
      runtime: 60
      filesize: 2
      storageclass: rook-ceph-block
      storagesize: 5Gi
```

To disable the need for PVs, simply comment out the `storageclass` key.

`pin` and `pin_server` will allow the benchmark runner pick what specific node to run FIO on.

Additionally, fio distributed will default to numjobs:1, and this current cannot be overwritten.

(*Technical Note*: If you are running kube/openshift on VMs make sure the diskimage or volume is preallocated.)
