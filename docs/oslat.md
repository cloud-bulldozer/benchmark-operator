# oslat

[oslat](https://github.com/xzpeter/oslat) is a test program for detecting OS level thread latency caused by unexpected system scheduling or interruptions (e.g., system ticks).
The goal of the oslat workload in the benchmark-operator is to run oslat inside of a container and measure the latency per core. This is

## Running oslat

Given that you followed instructions to deploy operator, you can modify [cr.yaml](../config/samples/oslat/cr.yaml) to your needs.
It is recommended to define pod requests and limits when running oslat test, to give guaranteed CPUs to the pods. It is also expected to have the
realtime kernel installed with required isolation for pods using the [Performance Add-On Operator](https://github.com/openshift-kni/performance-addon-operators).

The option **runtime_class** can be set to specify an optional
runtime_class to the podSpec runtimeClassName.  This is primarily
intended for Kata containers.

An example CR might look like this

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: oslat
  namespace: benchmark-operator
spec:
  elasticsearch:
    server: <ES_SERVER>
  workload:
    name: "oslat"
    args:
      node_selector: "<nodeSelector for the RT worker>"
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
# kubectl apply -f config/samples/oslat/cr.yaml # if edited the original one
# kubectl apply -f <path_to_file> # if created a new cr file
```
## Looking at results

You can look at the results from the oslat benchmark by doing

```bash
NAME=oslat-workload-xxxxxxx
oc logs -n benchmark-operator $NAME
```

## Cleanup

When you're done simply delete the benchmark CR; the job and its pod will be garbage-collected automatically.

