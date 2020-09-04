# FIO Distributed

[FIO](https://github.com/axboe/fio) -- The Flexible I/O Tester -- is a tool used for benchmarking
and stress-testing I/O subsystems. We generally refer to this type of workload as a "microbenchmark"
because it is used in a targeted way to determine the bottlenecks and limits of a system.

FIO has a native mechanism to run multiple servers concurrently against a data store. Our implementation
of the workload in Ripsaw takes advantage of this feature, spawning N FIO servers based on the
options provided by the user in the CR file. A single FIO client pod is then launched as the control
point for executing the workload on the server pods in parallel.

## Running Distributed FIO

The Custom Resource (CR) file for fio includes a significant number of options to offer the user
flexibility.

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: fio-benchmark
  namespace: my-ripsaw
spec:
  elasticsearch:
    server: my.es.server
    port: 9200
  clustername: myk8scluster
  test_user: my_test_user_name
  workload:
    name: "fio_distributed"
    args:
      prefill: true
      samples: 3
      servers: 3
      pin_server: ''
      # Chose to run servers in 'pod' or 'vm'
      # 'vm' needs kubevirt to be available
      # Default: pod
      kind: pod
      jobs:
        - write
        - read
      bs:
        - 4KiB
        - 64KiB
      numjobs:
        - 1
        - 8
      iodepth: 4
      read_runtime: 60
      read_ramp_time: 5
      filesize: 2GiB
      log_sample_rate: 1000
      storageclass: rook-ceph-block
      storagesize: 5Gi
      rook_ceph_drop_caches: True
      rook_ceph_drop_cache_pod_ip: 192.168.111.20
#######################################
#  EXPERT AREA - MODIFY WITH CAUTION  #
#######################################
#  global_overrides:
#    - key=value
  job_params:
    - jobname_match: w
      params:
        - fsync_on_close=1
        - create_on_open=1
    - jobname_match: read
      params:
        - time_based=1
        - runtime={{ workload_args.read_runtime }}
        - ramp_time={{ workload_args.read_ramp_time }}
    - jobname_match: rw
      params:
        - rwmixread=50
        - time_based=1
        - runtime={{ workload_args.read_runtime }}
        - ramp_time={{ workload_args.read_ramp_time }}
    - jobname_match: readwrite
      params:
        - rwmixread=50
        - time_based=1
        - runtime={{ workload_args.read_runtime }}
        - ramp_time={{ workload_args.read_ramp_time }}
#    - jobname_match: <search_string>
#      params:
#        - key=value
```

### Workload Loops

The options provided in the CR file are designed to allow for a nested set of job execution loops.
This allows the user to setup a series of jobs, usually of increasing intensity, and execute the job group
with a single request to the Ripsaw operator. This allows the user to run many jobs that may take hours
or even days to complete, and the jobs will continue through the nested loops unattended.

The workload loops are nested as such from the CR options:

```
+-------->numjobs---------+
|                         |
| +------>bs|bsrange----+ |
| |                     | |
| | +---->job---------+ | |
| | |                 | | |
| | | +-->samples---+ | | |
| | | |             | | | |
| | | |             | | | |
| | | +-------------+ | | |
| | +-----------------+ | |
| +---------------------+ |
+-------------------------+
```

### Understanding the CR options

>**A note about units:**
>
> For consistency in the CR file, we apply the fio option `kb_base=1000` in the jobfile configmap. The
> effect of this is that unit names are treated via IEC and SI standards, and thus units like `KB`, `MB`,
> and `GB` are considered base-10 (1KB = 1000B), and units like `KiB`, `MiB`, and `GiB` are base-2
> (1KiB = 1024B).
>
> However, note that fio (as of versions we have tested) does not react as might be expected to "shorthand"
> IEC units like `Ki` or `Mi` -- these will be treated as base-10 instead of base-2.
>
> Unfortunately, the [K8S resource model](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/scheduling/resources.md)
> specifies [explicitly](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/scheduling/resources.md#resource-quantities)
> the use of "shorthand" IEC units like `Ki` and `Mi`, and the use of the complete form of `KiB` or `MiB`
> will result in errors.
>
> Therefore, be aware in providing units to the CR values that fio options should use the `MiB` format
> while the `storagesize` option used for the K8S persistent volume claim should use the `Mi` format

#### metadata

*Values here will usually be left unchanged*

- **name**: The name the Ripsaw operator will use for the benchmark resource
- **namespace**: The namespace in which the benchmark will run

#### spec

- **elasticsearch**: (optional) Values are used to enable indexing of fio data; [further details are below](#indexing-in-elasticsearch-and-visualization-through-grafana)
- **clustername**: (optional) An arbitrary name for your system under test (SUT) that can aid indexing
- **test_user**: (optional) An arbitrary name for the user performing the tests that can aid indexing

#### spec.workload

- **name**: **DO NOT CHANGE** This value is used by the Ripsaw operator to trigger the correct Ansible role

#### spec.workload.args

*This is the meat of the workload where most of the adjustments to your needs will be made.*

- **samples**: Number of times to run the exact same workload. This is the innermost loop, as [described above](#workload-loops)
- **servers**: Number of fio servers that will run the specified workload concurrently
- **pin_server**: K8S node name (per `kubectl get nodes`) on which to run server pods
  > Note: Providing a node name to `pin_server` will result in *all* server pods running on the specified node.
- **jobs**: (list) fio job types to run, per `fio(1)` valid values for the `readwrite` option
  > Note: Under most circumstances, a `write` job should be provided as the first list item for `jobs`. This will
  > ensure that subsequent jobs in the list can use the files created by the `write` job instead of needing
  > to instantiate the files themselves prior to beginning the benchmark workload.
- **kind**: Can either be `pod` or `vm` to determine if the fio workload is run in a Pod or in a VM
  > Note: For VM workloads, you need to install Openshift Virtualization first
- **vm_image**: Whether to use a pre-defined VM image with pre-installed requirements. Necessary for disconnected installs.
  > Note: You can use my fedora image here: quay.io/mulbc/fed-fio \
  > Note: Only applies when kind is set to `vm`
- **vm_cores**: The number of CPU cores that will be available inside the VM. Default=1
  > Note: Only applies when kind is set to `vm`
- **vm_cores**: The amount of Memory that will be available inside the VM in Kubernetes format. Default=5G
  > Note: Only applies when kind is set to `vm`
- **bs**: (list) blocksize values to use for I/O transactions
  > Note: We set the `direct=1` fio option in the jobfile configmap. In order to avoid errors, the `bs` values
  > provided here should be a multiple of the filesystem blocksize (typically 4KiB). The [note above about units](#understanding-the-cr-options)
  > applies here.
- **bsrange**:(list) blocksize range values to use for I/O transactions
  > Note: We set the `direct=1` fio option in the jobfile configmap. In order to avoid errors, the `bsrange` values
  > provided here should be a multiple of the filesystem blocksize (typically 1KiB - 4KiB). The [note above about units](#understanding-the-cr-options)
  >  applies here.
  ```
  bsrange:
    - 1KiB-4KiB
    - 16KiB-64KiB
    - 256KiB-4096KiB
  ```
- **numjobs**: (list) Number of clones of the job to run on each server -- Total jobs will be `numjobs * servers`
- **iodepth**: Number of I/O units to keep in flight against a file; see `fio(1)`
- **read_runtime**: Amount of time in seconds to run `read` workloads (including `readwrite` workloads)
- **read_ramp_time**: Amount of time in seconds to ramp up `read` workloads (i.e., executing the workload without recording the data)
  > Note: We intentionally run `write` workloads to completion of the file size specified in order to ensure
  > that complete files are available for subsequent `read` workloads. All `read` workloads are time-based,
  > using these parameters, but note this behavious is configured via the EXPERT AREA section of the CR as
  > [described below](#expert-specjob_params), and therefore this may be adjusted to user preferences.
- **filesize**: The size of the file used for each job in the workload (per `numjobs * servers` as described above)
- **log_sample_rate**: Applied to fio options `log_avg_msec` and `log_hist_msec` in the jobfile configmap; see `fio(1)`
- **storageclass**: (optional) The K8S StorageClass to use for persistent volume claims (PVC) per server pod
- **pvcaccessmode**: (optional) The AccessMode to request with the persistent volume claim (PVC) for the fio server. Can be one of ReadWriteOnce,ReadOnlyMany,ReadWriteMany Default: ReadWriteOnce
- **pvcvolumemode**: (optional) The volmeMode to request with the persistent volume claim (PVC) for the fio server. Can be one of Filesystem,Block Default: Filesystem
  > Note: It is recommended to change this to `Block` for VM tests
- **storagesize**: (optional) The size of the PVCs to request from the StorageClass ([note units quirk per above](#understanding-the-cr-options))
- **rook_ceph_drop_caches**: (optional) If set to `True`, the Rook-Ceph OSD caches will be dropped prior to each sample
- **rook_ceph_drop_cache_pod_ip**: (optional) The IP address of the pod hosting the Rook-Ceph cache drop URL -- See [cache drop pod instructions](#dropping-rook-ceph-osd-caches) below
  > Technical Note: If you are running kube/openshift on VMs make sure the diskimage or volume is preallocated.
- **prefill**: (Optional) boolean to enable/disable prefill SDS
  - prefill requirement stems from Ceph RBD thin-provisioning - just creating the RBD volume doesn't mean that there is space allocated to read and write out there. For example, reads to an uninitialized volume don't even talk to the Ceph OSDs, they just return immediately with zeroes in the client.

#### EXPERT: spec.global_overrides

The `key=value` combinations provided in the list here will be appended to the `[global]` section of the fio
jobfile configmap. These options will therefore override the global values for all workloads in the loop.

#### EXPERT: spec.job_params

Under most circumstances, the options provided in the EXPERT AREA here should not be modified. The `key=value`
pairs under `params` here are used to append additional fio job options based on the job type. Each `jobname_match` in the list uses a "search string" to match a job name per `fio(1)`, and if a match is made, the `key=value` list items under `params` are appended to the `[job]` section of the fio jobfile configmap.

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

### Setup of Elasticsearch and Grafana

You'll need to standup the infrastructure required to index and visualize results.
We are using Elasticsearch as the database, and Grafana for visualizing.

#### Elasticsearch

Currently, we have tested with elasticsearch 7.0.1, so please deploy an elasticsearch instance.
There are are many guides that are quite helpful to deploy elasticsearch, for starters
you can follow the guide to deploy with docker by [elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/7.0/docker.html).

Once you have verified that you can access the elasticsearch, you'll have to create an index template for ripsaw-fio-logs.

We send fio logs to the index `ripsaw-fio-logs`, the template can be found in [arsenal](https://github.com/cloud-bulldozer/arsenal/blob/master/fio-distributed/elasticsearch/7.0.1/fio-logs.json).

Ripsaw will be indexing the fio result json to the index `ripsaw-fio-result`. For this, no template is required. However if you're an advanced user of elasticsearch, you can create it and edit its settings.

#### Grafana

Currently for fio-distributed, we have tested with grafana 6.3.0. An useful guide to deploy with docker
is present in [grafana docs](https://grafana.com/docs/installation/docker/#running-a-specific-version-of-grafana).

Once you've set it up, you can import the dashboard from the template in [arsenal](https://github.com/cloud-bulldozer/arsenal/blob/master/fio-distributed/grafana/6.3.0/dashboard.json).

You can then follow instructions to import dashboard like adding the data source following the [grafana docs](https://grafana.com/docs/reference/export_import/#importing-a-dashboard)

Please set the data source to point to the earlier, and the index name should be `ripsaw-fio-logs`.
The field for timestamp will always be `time_ms` .

### Changes to CR for indexing/visualization

In order to index your fio results to elasticsearch, you will need to define the parameters appropriately in
your workload CR file. The `spec.elasticsearch.server` and `spec.elasticsearch.port` values are required.
The `spec.clustername` and `spec.test_user` values are advised to allow for better indexing of your data.
