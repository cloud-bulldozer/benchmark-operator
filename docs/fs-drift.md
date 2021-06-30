# fs-drift Benchmark

[fs-drift](https://github.com/parallel-fs-utils/fs-drift) is a tool for testing distributed storage system longevity and
simulating aging of a distributed storage system.

it spawns a number of threads or processes doing a mix of filesystem operations. The user can customize parameters such
as the operation mix, the number of threads, the file size, the eventual number of files, and the shape of the directory
tree - see the benchmark documentation for details.  fs-drift requires that a storage class be defined so that pods have a persistent volume (PV) to perform I/O - however, it provides a default of local storage so that it can be run in environments like minikube for developers. 

## Running fs-drift Benchmark

Once the operator has been installed following the instructions, one needs to modify the [cr.yaml](../resources/crds/ripsaw_v1alpha1_fs-drift_cr.yaml) to customize workload parameters - the defaults are selected to demonstrate its operation and are not intended to specify a long-duration test.

The parameters in [cr.yaml](../resources/crds/ripsaw_v1alpha1_fs-drift_cr.yaml) would look similar to this example:

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: fs-drift
  namespace: benchmark-operator
spec:
  workload:
    name: fs-drift
    args:
      storageclass: cephfs
      storagesize: 1Gi
      worker_pods: 2
      threads: 5
      duration: 3600
      max_files: 1000
      max_file_sz_kb: 64
```

parameter names in fs-drift are specified in the command line as in the above link, or they can be
specified in a YAML input file also.   YAML input style is a little different -- double-dash prefix for parameter names
is omitted, and single dashes are converted to underscores.   So "--parameter-foo bar" becomes "parameter_foo: bar".

Operator CRs apparently also do not allow dashes in key names.  So for the above example, use the 
syntax "parameter_foo" instead of "--parameter-foo".  See resources/crds/ for an example of fs-drift CR.

The following fs-drift parameters will be overridden when fs-drift is used in ripsaw - do not specify these parameters yourself!

- top_directory - will always be set to the fs-drift/ subdirectory inside the mountpoint for the PV
- output_json - JSON counters are always output to counters.json inside the results/ subdirectory
- host_set - will always correspond to the set of pods being run
- response_times - will always be set to Y (yes) to collect response time data

The default value of **threads** parameter is 1, because we depend on creation of a large set of pods to distribute the
workload across not only other cores, but also other hosts.  However, this can be increased if desired.

The option **runtime_class** can be set to specify an optional
runtime_class to the podSpec runtimeClassName.  This is primarily
intended for Kata containers.

Once done creating/editing the CR file below, one can run it by:

```bash
kubectl apply -f resources/crds/ripsaw_v1alpha1_fs-drift_cr.yaml
```

Deploying the above(assuming worker_pods set to 2) would result in

```bash
kubectl get pods
NAME                                       READY     STATUS    RESTARTS   AGE
benchmark-operator-54bf9f4c44-llzwp        1/1       Running   0          1m
example-benchmark-fs-drift-client-1-benchmark   1/1       Running   0          22s
example-benchmark-fs-drift-client-2-benchmark   1/1       Running   0          22s
```

To see the output of the run one has to look at output from the workload generator pods:

```bash
for p in $(kubectl get pods | awk '/fs-drift/{ print $1 }') ; do \
 kubectl logs example-benchmark-fs-drift-client-1-benchmark -f $p ; \
done
```

fs-drift generates two additional kinds of output files: per-thread logs, and per-thread response times
(\*rsptimes.csv).

