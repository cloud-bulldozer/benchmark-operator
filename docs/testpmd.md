# TestPMD 

[TestPMD](https://doc.dpdk.org/guides/testpmd_app_ug/index.html) is anapplication  used to test the DPDK in a packet forwarding mode, here this application run inside a pod with SRIOV VF.

## Pre-requisites

This workload assumes a healthy cluster is runing with SR-IOV and Performance Add-On operators. 

* [SR-IOV](https://docs.openshift.com/container-platform/4.6/networking/hardware_networks/installing-sriov-operator.html) operator is required to create/assign VFs to the pods
* [PAO](https://docs.openshift.com/container-platform/4.6/scalability_and_performance/cnf-performance-addon-operator-for-low-latency-nodes.html) is required to prepare the worker node with Hugepages for DPDK application and isolate CPUs for workloads. 

### Sample SR-IOV configuration

These are used to create VFs and SRIOV networks, interface might vary

```yaml
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetworkNodePolicy
metadata:
  name: testpmd-policy
  namespace: openshift-sriov-network-operator
spec:
  deviceType: vfio-pci
  nicSelector:
    pfNames:
     - ens2f1
  nodeSelector:
    node-role.kubernetes.io/worker: ""
  numVfs: 20
  resourceName: intelnics
```

```yaml
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetwork
metadata:
  name: testpmd-sriov-network
  namespace: openshift-sriov-network-operator
spec:
  ipam: |
    {
      "type": "host-local",
      "subnet": "10.57.1.0/24",
      "rangeStart": "10.57.1.100",
      "rangeEnd": "10.57.1.200",
      "routes": [{
        "dst": "0.0.0.0/0"
      }],
      "gateway": "10.57.1.1"
    }
  spoofChk: "on"
  trust: "on"
  resourceName: intelnics
  networkNamespace: my-ripsaw

```

### Sample PAO configuration

The CPU and socket information might vary, use the below as an example. 

Add label to the MCP pool before creating the performance profile.
```sh
# oc label mcp worker machineconfiguration.openshift.io/role=worker
```

```yaml
---
apiVersion: performance.openshift.io/v1
kind: PerformanceProfile
metadata:
   name: testpmd-performance-profile-0
spec:
   cpu:
      isolated: "6,8,10,12,14,16,18,20,22,24,26,28"
      reserved: "0-5,7,9,11,13,15,17,19,21,23,25,27,29"
   hugepages:
      defaultHugepagesSize: "1G"
      pages:
         - size: "1G"
           count: 16
           node: 0
   numa:
      topologyPolicy: "best-effort"
   nodeSelector:
      node-role.kubernetes.io/worker: ""
   realTimeKernel:
     enabled: false
   additionalKernelArgs:
   - nosmt
   - tsc=reliable
```

## Running standalone TestPMD

A minimum configuration to run testpmd with in a pod, 

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: testpmd-benchmark
  namespace: my-ripsaw
spec:
  clustername: myk8scluster
  workload:
    name: testpmd
    args:
      privileged: true
      pin: false
      pin_testpmd: "node-0"      
      pin_trex: "node-0"      
      networks:
        testpmd:
          - name: testpmd-sriov-network
            count: 2  # Interface count, Min 2
        trex:
          - name: testpmd-sriov-network
            count: 2
```

Additional advanced pod and testpmd.trex specification can also be supplied in CR definition yaml(below specs are current defaults)


Pod specification arguments,
```yaml
  workload:
    ...
    pod_hugepage_1gb_count: 4Gi 
    pod_memory: "1000Mi"
    pod_cpu: 6
```

TestPMD arguments for more description refer [here](https://manpages.debian.org/experimental/dpdk/testpmd.1.en.html)
```yaml
  workload:
    ...
    socket_memory: 1024,0 # This memory is allocated based on your node hugepage allocation, ex. for NUMA 0.
    memory_channels: 4
    forwarding_cores: 4
    rx_queues: 1
    tx_queues: 1
    rx_descriptors: 1024
    tx_descriptors: 1024
    forward_mode: "mac"
    stats_period: 1
```

TRex arguments 
```yaml
  workload:
    ...
    duration: 30 # In Seconds
    packet_size: 64
    packet_rate: "10kpps" # All lower case and only support Packets per seconds
    num_stream: 1
```

## Container Images

TestPMD Pod uses this [image](https://catalog.redhat.com/software/containers/openshift4/dpdk-base-rhel8/5e32be6cdd19c77896004a41?container-tabs=dockerfile&tag=latest&push_date=1610346978000)
it can be overriden by supplying additional inputs in CR definition yaml, provided `testpmd` command will be executable from the image `WORKDIR` with additional environment variables

```yaml
  workload:
    ...
    image_testpmd: "registry.redhat.io/openshift4/dpdk-base-rhel8:v4.6"
    image_pull_policy: "Always"
    environments:
      testpmd_mode: "direct" ## Just an example
```

TRex Pod uses [snafu](https://quay.io/repository/cloud-bulldozer/trex) based image

## Result

This CR will create TestPMD pod and TRex pod using the SRIOV network provided and run traffic between them. The result can be viewed as below,

```sh
# oc get benchmark 
NAME                TYPE      STATE      METADATA STATE   CERBERUS        UUID                                   AGE
testpmd-benchmark   testpmd   Complete   not collected    not connected   35daf5ac-2edf-5e34-a6cc-17fcda055937   4m36s

# oc get pods
NAME                                     READY   STATUS      RESTARTS   AGE
benchmark-operator-7fff779945-d9485      3/3     Running     0          4m16s
testpmd-application-pod-35daf5ac-nxc4v   1/1     Running     0          2m41s
trex-traffic-gen-pod-35daf5ac-dslzh      0/1     Completed   0          2m20s

oc logs trex-traffic-gen-pod-35daf5ac-dslzh
2021-01-28T17:41:02Z - INFO     - MainProcess - run_snafu: logging level is INFO
2021-01-28T17:41:02Z - INFO     - MainProcess - wrapper_factory: identified trex as the benchmark wrapper
2021-01-28T17:41:02Z - INFO     - MainProcess - trigger_trex: Starting TRex Traffic Generator..
2021-01-28T17:41:47Z - INFO     - MainProcess - trigger_trex: {
  "cluster_name": "myk8scluster",
  "cpu_util": 0.22244608402252197,
  "duration": 30,
  "kind": "pod",
  "num_stream": 1,
  "packet_rate": "10kpps",
  "packet_size": 64,
  "rx_bps": 17426300.0,
  "rx_drop_bps": 0.0,
  "rx_pps": 19984.2890625,
  "testpmd_node": "worker000-fc640",
  "trex_node": "worker001-fc640",
  "tx_bps": 16786740.0,
  "tx_pps": 19984.212890625,
  "user": "snafu",
  "uuid": "35daf5ac",
  "workload": "testpmd"
}
2021-01-28T17:41:47Z - INFO     - MainProcess - trigger_trex: Finished Generating traffic..
2021-01-28T17:41:47Z - INFO     - MainProcess - run_snafu: Duration of execution - 0:00:45, with total size of 240 bytes
```

### Elasticsearch

To publish data to Elasticsearch, the procedure is same as other workloads. 

```yaml
spec:
  clustername: testpmd
  test_user: snafu
  elasticsearch:
    url: https://search-perfscale-dev.server.com:443
```
