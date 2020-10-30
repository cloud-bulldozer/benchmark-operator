# oslat

[oslat](https://github.com/xzpeter/oslat) is a test program for detecting OS level thread latency caused by unexpected system scheduling or interruptions (e.g., system ticks).
The goal of the oslat workload in the benchmark-operator is to run oslat inside of a container and measure the latency per core. This is

## Running oslat

Given that you followed instructions to deploy operator, you can modify [cr.yaml](../resources/crds/ripsaw_v1alpha1_oslat.yaml) to your needs.
It is recommended to define pod requests and limits when running oslat test, to give guaranteed CPUs to the pods. It is also expected to have the
realtime kernel installed with required isolation for pods using the [Performance Add-On Operator](https://github.com/openshift-kni/performance-addon-operators).

An example CR might look like this

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: oslat
  namespace: my-ripsaw
spec:
  elasticsearch:
    server: <ES_SERVER>
    port: <ES_PORT>
  workload:
    name: "oslat"
    args:
      runtime: "1m"
      disable_cpu_balance: true
      use_taskset: true
      pod:
        requests:
          memory: "200Mi"
          cpu: "4"
        limits:
          memory: "200Mi"
          cpu: "4"
```

You can run it by:

```bash
oc apply -f resources/crds/ripsaw_v1alpha1_oslat_cr.yaml # if edited the original one
```
## Looking at results

You can look at the results from the oslat benchmark by doing

```bash
NAME=oslat-workload-xxxxxxx
oc logs -n my-ripsaw $NAME
```

## Cleanup

When you're done simply delete the benchmark CR; the job and its pod will be garbage-collected automatically.

