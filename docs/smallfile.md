# Smallfile Benchmark

[Smallfile](https://github.com/distributed-system-analysis/smallfile) is a python-based distributed POSIX workload generator which can be used to quickly measure performance for a variety of metadata-intensive workloads across an entire cluster.

## Running Smallfile Benchmark using Ripsaw
Once the operator has been installed following the instructions, one needs to modify the clients parameter(which is currently set to 0), to value greater than 0 in [cr.yaml](../config/samples/smallfile/cr.yaml) to run default "create" the test. Also, in addtion to that, smallfile operator is completely dependent on storageclass and storagesize. Please make sure to double check the parameters in CRD file.

Smallfile operator also gives the leverage to run multiple test operations in a user-defined sequence. Like in the [Custom Resource Definition file](../config/samples/smallfile/cr.yaml), the series of operations can be specified as a list. 

NOTE: While running the sequence of tests using smallfile workload, please make sure that the initial operation must be create, and the "cleanup" operation should come in termination, else smallfile might produce error due to meaningless sequence of tests. For example:

```bash

operation: ["read","append","create", "delete","cleanup"]
#This will be meaningless sequence of test as trying to read something, which has not been created yet.The same logic applies for the append test as well. Hence, smallfile will produce error.
```

## Adding More options in smallfile tests

Smallfile also comes with a variety of configurable options that can be added by the user to the CR for running tests, documented [at its github site here](https://github.com/distributed-system-analysis/smallfile#readme) .   To obtain the YAML parameter name, remove the 2 preceding dashes and convert remaining dashes to underscores and append a colon character.   For example, **--file-size** becomes **file_size:** .  Parameters that **are not** usable in the smallfile CR include:

* --yaml-input-file - used by the benchmark
* --operation - you specify this in the CR in the operation list
* --top - you do not specify this, Kubernetes points smallfile to the PV mountpoint
* --response-times - used by the benchmark
* --output-json - used by the benchmark
* --network-sync-dir - not applicable for pods
* --permute-host-dirs - not applicable for pods
* --remote-pgm-dir - not applicable for pods

Once done creating/editing the resource file, one can run it by:

```bash
# kubectl apply -f config/samples/smallfile/cr.yaml # if edited the original one
# kubectl apply -f <path_to_file> # if created a new cr file
```

Deploying the above(assuming clients set to 1) would result in
```bash
$ kubectl get pods
NAME                                                   READY     STATUS    RESTARTS   AGE
benchmark-operator-7c6bc98b8c-2j5x5                    2/2       Running   0          47s
example-benchmark-smallfile-client-1-benchmark-hwj4b   1/1       Running   0          33s
example-benchmark-smallfile-publisher...   
```

To see the output of the run one has to run `kubectl logs <client>`. This looks *approximately* like:
```bash

$ kubectl logs example-benchmark-smallfile-client-1-benchmark-hwj4b
Waiting For all Smallfile Pods to get ready ...
Executing Smallfile...
2021-08-24T20:26:32Z - INFO     - MainProcess - trigger_smallfile: running:smallfile_cli.py --operation create --top /mnt/pvc/smallfile_test_data --output-json /var/tmp/RESULTS/1/create.json --response-times Y --yaml-input-file /tmp/smallfile/smallfilejob
2021-08-24T20:26:32Z - INFO     - MainProcess - trigger_smallfile: from current directory /opt/snafu
                                 version : 3.2
                           hosts in test : None
                        launch by daemon : False
                   top test directory(s) : ['/mnt/pvc/smallfile_test_data']
                               operation : create
                            files/thread : 10000
                                 threads : 1
           record size (KB, 0 = maximum) : 0
                          file size (KB) : 4
                  file size distribution : fixed
                           files per dir : 100
                            dirs per dir : 10
              threads share directories? : N
                         filename prefix : 
                         filename suffix : 
             hash file number into dir.? : N
                     fsync after modify? : N
          pause between files (microsec) : 0
                             auto-pause? : N
 delay after cleanup per file (microsec) : 0
             minimum directories per sec : 50
                             total hosts : 30
                    finish all requests? : Y
                              stonewall? : Y
                 measure response times? : Y
                            verify read? : Y
                                verbose? : False
                          log to stderr? : False
host = smallfile-client-1-benchmark-84ad212e-9h454,thr = 00,elapsed = 0.592771,files = 10000,records = 10000,status = ok
total threads = 1
total files = 10000
total IOPS = 16869
total data =     0.038 GiB
100.00% of requested files processed, warning threshold is  70.00
elapsed time =     0.593
files/sec = 16869.919582
IOPS = 16869.919582
MiB/sec = 65.898123
2021-08-24T20:26:37Z - INFO     - MainProcess - trigger_smallfile: completed sample 1 for operation create , results in /var/tmp/RESULTS/1/create.json
...
```
