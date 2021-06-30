# Smallfile Benchmark

[Smallfile](https://github.com/distributed-system-analysis/smallfile) is a python-based distributed POSIX workload generator which can be used to quickly measure performance for a variety of metadata-intensive workloads across an entire cluster.

## Running Smallfile Benchmark using Ripsaw
Once the operator has been installed following the instructions, one needs to modify the clients parameter(which is currently set to 0), to value greater than 0 in  [ripsaw_v1alpha1_smallfile_cr.yaml](../resources/crds/ripsaw_v1alpha1_smallfile_cr.yaml) to run default "create" the test. Also, in addtion to that, smallfile operator is completely dependent on storageclass and storagesize. Please make sure to double check the parameters in CRD file.

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: example-benchmark
  namespace: benchmark-operator
spec:
  workload:
    name: smallfile
    args:
      clients: 1
      operation: ["create"]
      threads: 5
      file_size: 64
      files: 100
      storageclass: rook-ceph-block # Provide if PV is needed
      storagesize: 5Gi # Provide if PV is needed
```

Smallfile operator also gives the leverage to run multiple test operations in a user-defined sequence. Like in the [Custom Resource Definition file](../resources/crds/ripsaw_v1alpha1_smallfile_cr.yaml), the series of operation can be mentioned as:

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: example-benchmark
  namespace: benchmark-operator
spec:
  workload:
    name: smallfile
    args:
      clients: 1
      operation: ["create","read","append", "delete"]
      threads: 5
      file_size: 64
      files: 100
      storageclass: rook-ceph-block # Provide if PV is needed
      storagesize: 5Gi # Provide if PV is needed
```

NOTE: While running the sequence of tests using smallfile workload, please make sure that the initial operation must be create, and the "delete" operation should come in termination, else smallfile might produce error due to meaningless sequence of tests. For example:
```bash
operation: ["read","append","create", "delete"]
#This will be meaningless sequence of test as trying to read something, which has not been created yet.The same logic applies for the append test as well. Hence, smallfile will produce error.
```

## Adding More options in smallfile tests

Smallfile also comes with a variety of configurable options for running tests, following are the parameters that can be added to CR file:

 * **response_times** – if Y then save response time for each file operation in a
  rsptimes\*csv file in the shared network directory. Record format is
  operation-type, start-time, response-time. The operation type is included so
  that you can run different workloads at the same time and easily merge the
  data from these runs. The start-time field is the time that the file
  operation started, down to microsecond resolution. The response time field is
  the file operation duration down to microsecond resolution.
 * **file_size_distribution** – only supported value today is exponential.
 * **record_size** -- record size in KB, how much data is transferred in a single
  read or write system call.  If 0 then it is set to the minimum of the file
  size and 1-MiB record size limit.
 * **files_per_dir** -- maximum number of files contained in any one directory.
 * **dirs_per_dir** -- maximum number of subdirectories contained in any one
  directory.
 * **hash_into_dirs** – if Y then assign next file to a directory using a hash
  function, otherwise assign next –files-per-dir files to next directory.
 * **same_dir** -- if Y then threads will share a single directory.
 * **network_sync_dir** – don't need to specify unless you run a multi-host test
  and the –top parameter points to a non-shared directory (see discussion
  below). Default: network_shared subdirectory under –top dir.
 * **permute_host_dirs** – if Y then have each host process a different
  subdirectory tree than it otherwise would (see below for directory tree
  structure).
 * **xattr_size** -- size of extended attribute value in bytes (names begin with
  'user.smallfile-')
 * **xattr_count** -- number of extended attributes per file
 * **prefix** -- a string prefix to prepend to files (so they don't collide with
previous runs for example)
 * **suffix** -- a string suffix to append to files (so they don't collide with
  previous runs for example)
 * **incompressible** – if Y then generate a pure-random file that
  will not be compressible (useful for tests where intermediate network or file
  copy utility attempts to compress data
 * **record_ctime_size** -- if Y then label each created file with an
  xattr containing a time of creation and a file size. This will be used by
  –await-create operation to compute performance of asynchonous file
  replication/copy.
 * **finish** -- if Y, thread will complete all requested file operations even if
  measurement has finished.
 * **stonewall** -- if Y then thread will measure throughput as soon as it detects
  that another thread has finished.
 * **verify_read** – if Y then smallfile will verify read data is correct.
 * **remote_pgm_dir** – don't need to specify this unless the smallfile software
  lives in a different directory on the target hosts and the test-driver host.
 * **pause** -- integer (microseconds) each thread will wait before starting next
  file.
 * **runtime_class** - If this is set, the benchmark-operator will apply the runtime_class to the podSpec runtimeClassName.


Once done creating/editing the resource file, one can run it by:

```bash
# kubectl apply -f resources/crds/ripsaw_v1alpha1_smallfile_cr.yaml # if edited the original one
# kubectl apply -f <path_to_file> # if created a new cr file
```

Deploying the above(assuming clients set to 1) would result in
```bash
$ kubectl get pods
NAME                                                   READY     STATUS    RESTARTS   AGE
benchmark-operator-7c6bc98b8c-2j5x5                    2/2       Running   0          47s
example-benchmark-smallfile-client-1-benchmark-hwj4b   1/1       Running   0          33s
```

To see the output of the run one has to run `kubectl logs <client>`. This is shown below:
```bash
$ kubectl logs example-benchmark-smallfile-client-1-benchmark-hwj4b
create
RUnning_OPERATION_create

top: /mnt/pvc/smallfile_test_data
threads: 5
file-size: 64
files: 100
                                version : 3.1
                          hosts in test : None
                       launch by daemon : False
                  top test directory(s) : ['/mnt/pvc/smallfile_test_data']
                              operation : create
                           files/thread : 100
                                threads : 5
          record size (KB, 0 = maximum) : 0
                         file size (KB) : 64
                 file size distribution : fixed
                          files per dir : 100
                           dirs per dir : 10
             threads share directories? : N
                        filename prefix :
                        filename suffix :
            hash file number into dir.? : N
                    fsync after modify? : N
         pause between files (microsec) : 0
            minimum directories per sec : 50
                   finish all requests? : Y
                             stonewall? : Y
                measure response times? : N
                           verify read? : Y
                               verbose? : False
                         log to stderr? : False
                          ext.attr.size : 0
                         ext.attr.count : 0
host = example-benchmark-smallfile-client-1-benchmark-hwj4b,thr = 00,elapsed = 0.015719,files = 100,records = 100,status = ok
host = example-benchmark-smallfile-client-1-benchmark-hwj4b,thr = 01,elapsed = 0.020679,files = 100,records = 100,status = ok
host = example-benchmark-smallfile-client-1-benchmark-hwj4b,thr = 02,elapsed = 0.028791,files = 100,records = 100,status = ok
host = example-benchmark-smallfile-client-1-benchmark-hwj4b,thr = 03,elapsed = 0.029367,files = 100,records = 100,status = ok
host = example-benchmark-smallfile-client-1-benchmark-hwj4b,thr = 04,elapsed = 0.029750,files = 100,records = 100,status = ok
total threads = 5
total files = 500
total IOPS = 500
total data =     0.031 GiB
100.00% of requested files processed, minimum is  70.00
elapsed time =     0.030
files/sec = 16806.661271
IOPS = 16806.661271
MiB/sec = 1050.41633
```
