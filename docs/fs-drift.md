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
  name: fs-drift-benchmark
  namespace: ripsaw
  storageclass: cephfs
  storagesize: 1-TB
spec:
  workload:
    name: fs-drift
    args:
      duration: 3600
      max-files: 1000
      max-file-sz-kb: 4096
```

parameter names in fs-drift are specified in the command line like this: --my-parameter

But Operator CRs apparently do not allow dashes in key names.  So for the above example, use the 
syntax "my_parameter" instead of "--my-parameter" and the fs-drift ripsaw plugin will convert it.

The following parameters will be overridden when fs-drift is used in ripsaw:

- top_directory - will always be set to the fs-drift/ subdirectory inside the mountpoint for the PV
- output_json - JSON counters are always output to counters.json inside the results/ subdirectory
- host_set - will always correspond to the set of pods being run
- response_times - will always be set to Y (yes) to collect response time data

The default value of **threads** parameter is 1, because we depend on creation of a large set of pods to distribute the
workload across not only other cores, but also other hosts.  However, this can be increased if desired.

The default value of **report-interval** parameter will be maximum of 1% of test duration and 1 second, but this can be
overridden by the user.

The default value of storageclass is in [local-sc.yaml](../resources/storageclass/local-sc.yaml).   Note that this is a
RWX (ReadWriteMany) storage class - fs-drift does not yet support RWO (ReadWriteOnce) storage classes.  

Once done creating/editing the resource file, one can run it by:

```bash
# kubectl apply -f resources/crds/ripsaw_v1alpha1_fs-drift_cr.yaml # if edited the original one
# kubectl apply -f <path_to_file> # if created a new cr file
```

Deploying the above(assuming clients set to 2) would result in

```bash
kubectl get pods
NAME                                       READY     STATUS    RESTARTS   AGE
benchmark-operator-54bf9f4c44-llzwp        1/1       Running   0          1m
example-benchmark-fs-drift-client-1-benchmark   1/1       Running   0          22s
example-benchmark-fs-drift-client-2-benchmark   1/1       Running   0          22s
```

Since we have storageclass and storagesize defined in the CR, the corresponding status of persistent volumes is seen like this:

```bash
kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM              STORAGECLASS      REASON    AGE
pvc-0f20b50d-5c57-11e9-b95c-d4ae528b96c1   1TiB       RWX            Delete           Bound     benchmark/claim1   rook-ceph-fs                19s
```

To see the output of the run one has to run `kubectl logs <first-client>`. The first pod is the one that coordinates the
test (and is also a workload generator).   This is shown below:

```bash
 kubectl logs example-benchmark-fs-drift-client-1-benchmark -f
TBS
```

The shared PV will contain a directory called fs-drift/results/  which will include all of the logs from all of the
pods, and this will be copied out of the PV at the end of the test to a local directory, which can then be imported
to elastic search or viewed directly.

