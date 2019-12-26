# VDBench

[VDbench](https://www.oracle.com/downloads/server-storage/vdbench-downloads.html) -- is a tool used for benchmarking
and stress-testing I/O subsystems. We generally refer to this type of workload as a "microbenchmark"
because it is used in a targeted way to determine the bottlenecks and limits of a system.
this tool written and maintain by oracle and it is highly used my the industry.

VDbench can be run as a singel-host or multi-host test and has a native mechanism to run multiple servers concurrently
against a data store. Our implementation of the workload in Ripsaw takes advantage of the native multi-host feature, 
spawning N vdbench servers based on the options provided by the user in the CR file. A single vdbench client pod is then 
launched as the control point for executing the workload on the server pods in parallel.

We implement the Filesystem option of the vdbench benchmark and not the RAW device test - this might be in future release.
## Running VDBench

The Custom Resource (CR) file for fio includes a significant number of options to offer the user
flexibility.

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: vdbench-benchmark
  namespace: my-ripsaw
spec:
  elasticsearch:
    server: <es_server>
    port: 9200
  clustername: myk8scluster
  test_user: ripsaw
  workload:
    name: "vdbench"
    args:
      servers: 30
      pin_server: 'vdbench'
      threads: 8
      fileselect: random
      fileio: random
      jobs:
        - name: RandomRead
          op: read
        - name: RandomWrite
          op: write
        - name: RandomMix75
          op: read
          rdpct: 75
      iorate:
        - max
        - curve
      curve: (10,20,30,50,65,70,80,83,85,88,90,92,95,97,100)
      bs:
        - 4k
        - 16k
      depth: 3
      width: 4
      files: 256
      file_size: 5
      runtime: 600
      pause: 5
      storageclass: ocs-storagecluster-ceph-rbd
      storagesize: 100Gi
      #rook_ceph_drop_caches: True
      #rook_ceph_drop_cache_pod_ip: 192.168.111.20
```

### Workload Loops

The options provided in the CR file are designed to allow for a nested set of job execution loops.
This allows the user to setup a series of jobs, usually of increasing intensity, and execute the job group
with a single request to the Ripsaw operator. This allows the user to run many jobs that may take hours
or even days to complete, and the jobs will continue through the nested loops unattended.

The workload loops are nested as such from the CR options:

```
+-------->blocksize-------+
|                         |
| +--------->job--------+ |
| |                     | |
| |                     | |
| |                     | |
| +---------------------+ |
+-------------------------+
```

### Understanding the CR options
>**A note about units:**
>
> All units in this CR file, are base-2 units (1KiB = 1K = 1024B)
>

#### metadata
*Values here will usually be left unchanged*
- **name**: The name the Ripsaw operator will use for the benchmark resource
- **namespace**: The namespace in which the benchmark will run

#### spec
- **elasticsearch**: (optional) Values are used to enable indexing of vdbench data; [further details are below](#indexing-in-elasticsearch-and-visualization-through-grafana)
- **clustername**: (optional) An arbitrary name for your system under test (SUT) that can aid indexing
- **test_user**: (optional) An arbitrary name for the user performing the tests that can aid indexing

#### spec.workload
- **name**: **DO NOT CHANGE** This value is used by the Ripsaw operator to trigger the correct Ansible role

#### spec.workload.args
*This is the meat of the workload where most of the adjustments to your needs will be made.*
- **servers**: Number of vdbench servers that will run the specified workload concurrently
- **pin_server**: value of node label `app-node` on which to run server pods
> Note: Providing a node label to `pin_server` will result in *all* server pods running on the nodes with that label.
>       so, make sure that you label your tested nodes with : app-node=`pin_server`
- **threads**: Number of I/O threads to to run in each test
- **fileselect**: The way files selected - can be random of sequential
- **fileio**: The I/O type that will be run -  can be random of sequential
- **jobs**: (list) vdbench job types to run, per `vdbench(1)` valid values for the `operation` option
> Note: Each job have 3 parameters : `name` - the name of the job , `op` - the actual operation (we implement read and write)
>       and `rdpct` (optional) - read percentage - this need to be add only for mix workload, in that case the `op` need to be **read** 
- **iorate**: (list) the I/O rate that the test will try to get.
> Note: You can give **max** to find the maximum rate that it can be achieve, or **curve** for running series of test, when 
>       the first test is to find the max io rate.
>       In case of **curve**, the **curve** parameter is mandatory.
- **curve**: (optional ?) - list of percentages of iorate to achieve. (e.g: `(10,20,30,50,80,90,100)`)
- **bs**: (list) blocksize values to use for I/O transactions
> Note: We set the `openflags=o_direct` for vdbench fsd in the jobfile configmap. In order to avoid errors, the `bs` values
> provided here should be a multiple of the filesystem blocksize (typically 4KiB). The [note above about units](#understanding-the-cr-options)
> applies here. 
> The unit are **mandatory** , if no unit supply it will used the number as **byte**, so make sure to supply - **k / m**
- **depth**: The depth of the directory structure to create.
- **width**: The width of the directory structure to create.
- **files**: The number of files to create in each sub directory - Total number of files is : (width ^ depth) * files
- **file_size**: The size of the each file used in the workload - **the file unit is in MB.**
- **runtime**: Amount of time in seconds to run each workload
- **pause**: Time in minute to pause after each workload is running.
- **storageclass**: (optional) The K8S StorageClass to use for persistent volume claims (PVC) per server pod
- **storagesize**: (optional) The size of the PVCs to request from the StorageClass ([note units quirk per above](#understanding-the-cr-options))
- **rook_ceph_drop_caches**: (optional) If set to `True`, the Rook-Ceph OSD caches will be dropped prior to each sample
- **rook_ceph_drop_cache_pod_ip**: (optional) The IP address of the pod hosting the Rook-Ceph cache drop URL -- See [cache drop pod instructions](#dropping-rook-ceph-osd-caches) below
> Technical Note: If you are running kube/openshift on VMs make sure the diskimage or volume is preallocated.

## Dropping Rook-Ceph OSD Caches

Dropping the OSD caches before workloads is a normal and advised part of tests that involve storage I/O.
Doing this with Rook-Ceph requires a privileged pod running the same namespace as the Ceph pods and with
the Ceph command tools available. To facilitate this, we provide the
[resources/rook_ceph_drop_cache_pod.yaml](../resources/rook_ceph_drop_cache_pod.yaml) file, which will
deploy a pod with the correct permissions and tools, as well as running a simple HTTP listener to trigger
the cache drop by URL.
**You must deploy this privileged pod in order for the drop caches requests in the workload to function.**

```bash
kubectl apply -f resources/rook_ceph_drop_cache_pod.yaml
```

*Note: If Ceph is in a namespace other than `rook-ceph` you will need to modify the provided YAML accordingly.*

Since the cache drop pod is deployed with host networking, the pod will take on the IP address
of the node on which it is running. You will need to use this IP address in the CR file as described above.

```bash
kubectl get pod -n rook-ceph rook-ceph-osd-cache-drop --template={{.status.podIP}}
```

## Indexing in elasticsearch and visualization through Grafana

Currently we are not supported this option, it will be supported in future release.
In this version of the CR, you need to deploy it from a script that then monitor the clien log for **Test Run Finished**
that's mean the benchmark finished and you can take out the test fesults from the pod by running :
```
kubectl cp vdbench-client-<id>:/tmp/Results.tar.gz Results.tar.gz
```
All results and test log are it this tar.gz file.

the benchmark will sleep for 5 Min. before it state will change to **Compleat**, after that you can not pull the tar.gz file
and you can only take the log with the command :
```
kubectl logs vdbench-client-<id>
```
