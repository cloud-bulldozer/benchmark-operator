# Uperf

[Uperf](http://uperf.org/) is a network performance tool

## Running UPerf

Given that you followed instructions to deploy operator,
you can modify [cr.yaml](../config/samples/uperf/cr.yaml)

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: uperf-benchmark
  namespace: benchmark-operator
spec:
  elasticsearch:
    url: "http://es-instance.com:9200"
  workload:
    name: uperf
    args:
      client_resources:
        requests:
          cpu: 500m
          memory: 500Mi
        limits:
          cpu: 500m
          memory: 500Mi
      server_resources:
        requests:
          cpu: 500m
          memory: 500Mi
        limits:
          cpu: 500m
          memory: 500Mi
      serviceip: false
      dualstack: false
      runtime_class: class_name
      hostnetwork: false
      networkpolicy: false
      pin: false
      kind: pod
      pin_server: "node-0"
      pin_client: "node-1"
      pair: 1
      multus:
        enabled: false
      samples: 1
      test_types:
        - stream
      protos:
        - tcp
      sizes:
        - 16384
      nthrs:
        - 1
      runtime: 30
```

 By default, the uperf server and client pods will be preferably scheduled on different nodes, thanks to a `podAntiAffinity` rule. In scenarios with more than 1 pair, all clients and servers will be scheduled to the same node. 

`client_resources` and `server_resources` will create uperf client's and server's containers with the given k8s compute resources respectively [k8s resources](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/)

`serviceip` will place the uperf server behind a K8s [Service](https://kubernetes.io/docs/concepts/services-networking/service/)

`dualstack` will use IPv6 for establishing the connectivity between uperf client(s) and server(s). The environment has to be properly configured with dualstack previous to running the test. Only loadbalancer type services are supported for now.

`runtime_class` If this is set, the benchmark-operator will apply the runtime_class to the podSpec runtimeClassName.

*Note:* `runtime_class` has only been tested with Kata containers. Only include `runtime_class` if using Kata containers.

`annotations` If this is set, the benchmark-operator will set the specified annotations on the pods' metadata.

`server_annotations` If this is set, the benchmark-operator will set the specified annotations on the server pods' metadata.

`client_annotations` If this is set, the benchmark-operator will set the specified annotations on the client pods' metadata.

`hostnetwork` will test the performance of the node the pod will run on.

`networkpolicy` will create a simple networkpolicy for ingress

`pin` will allow the benchmark runner place nodes on specific nodes, using the `hostname` label.

`pin_server` what node to pin the server pod to.

`pin_client` what node to pin the client pod to.

`pair` how many instances of uperf client-server pairs. `pair` is applicable for `pin: true` only.

`multus[1]` Configure our pods to use multus.

`samples` how many times to run the tests. For example

[1] https://github.com/intel/multus-cni/tree/master/examples

```yaml
      samples: 3
      density_range: [1,1]
      test_types:
        - stream
      protos:
        - tcp
      sizes:
        - 1024
        - 16384
      nthrs:
        - 1
      runtime: 30
```

Will run `stream` w/ `tcp` and message size `1024` three times and
`stream` w/ `tcp` and message size `16384` three times. This will help us
gain confidence in our results.

### Asymmetric Request-Response

For the request-response (rr) `test_type`, it is possible to provide the `sizes` values as a
list of two values where the first value is the write size and the second value is the read
size.

For example:
```yaml
      samples: 3
      density_range: [1,1]
      test_types:
        - rr
      protos:
        - tcp
      sizes:
        - 1024
        - [8192, 4096]
      nthrs:
        - 1
      runtime: 30
```
Will run the `rr` test with `tcp`, first with a symmectic size of `1024` and then with an
asymmetric size of `8192` write and `4096` read.

### Multus

If the user desires to test with Multus, use the below Multus `NetworkAtachmentDefinition`
as an example:

```
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-range-0
spec:
  config: '{
            "cniVersion": "0.3.1",
            "type": "macvlan",
            "master": "eno1",
            "mode": "bridge",
            "ipam": {
                    "type": "host-local",
                    "ranges": [
                    [ {
                       "subnet": "11.10.0.0/16",
                       "rangeStart": "11.10.1.20",
                       "rangeEnd": "11.10.3.50"
                    } ] ]
            }
        }'
---
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-range-1
spec:
  config: '{
            "cniVersion": "0.3.1",
            "type": "macvlan",
            "master": "eno1",
            "mode": "bridge",
            "ipam": {
                    "type": "host-local",
                    "ranges": [
                    [ {
                       "subnet": "11.10.0.0/16",
                       "rangeStart": "11.10.1.60",
                       "rangeEnd": "11.10.3.90"
                    } ] ]
            }
        }'
```

This will use the same IP subnet across nodes, but not overlap
IP addresses.

To enable Multus in Ripsaw, here is the relevant config.

```
      ...
      multus:
        enabled: true
        client: "macvlan-range-0"
        server: "macvlan-range-1"
      pin: true
      pin_server: "openshift-master-0.dev4.kni.lab.eng.bos.redhat.com"
      pin_client: "openshift-master-1.dev4.kni.lab.eng.bos.redhat.com"
      ...

```
### Advanced Service types

Benchmark operator now also supports different service types, it can create `NodePort` and `LoadBalancer` (only metallb) 
type services along with the current default `ClusterIP` type.

No pre-requisites needed for `NodePort` service, as long as the ports used by uperf(30000 to 30012) are allowed at the node level, 
which is the cluster default.

```
NAME                TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S) 
uperf-service-np    NodePort       172.30.177.81   <none>            30000:31955/TCP,30001:31935/TCP,30002:31942/TCP,30001:31935/UDP,30002:31942/UDP
```

For `metallb` type, there are certain pre-requisites, 
1.  Installation of [MetalLB](https://metallb.universe.tf/) operator and CRD
2.  Configuration of [BGP](https://github.com/metallb/metallb-operator#create-a-bgp-peer-object)
3.  Configuration of [AddressPool](https://github.com/metallb/metallb-operator#create-an-address-pool-object) for lb service
4.  Configuration of extenal router for BGP

`metallb` type creates 2 services per benchmark CR (for each protocol, `tcp` and `udp`) and they will share the external IP like below

```
NAME                TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S) 
uperf-service-lb    LoadBalancer   172.30.177.99   192.168.216.102   30000:30976/TCP,30001:30652/TCP,30002:30099/TCP 
uperf-service-lb2   LoadBalancer   172.30.126.71   192.168.216.102   30001:31312/UDP,30002:30776/UDP 
```

#### CR file inputs

##### For NodePort
```yaml
      ...
      name: uperf
      serviceip: true
      servicetype: "nodeport"
      ...
```

##### For MetalLB
`metallb`
```yaml
      ...
      name: uperf
      serviceip: true
      servicetype: "metallb"
      metallb:
        addresspool: "addresspool-l3"
        service_etp: "Cluster" # Either `Cluster` or `Local`
      ...
```

## Running Uperf in VMs through kubevirt/cnv [Preview]
Note: this is currently in preview mode.


### Pre-requisites

You must have configured your k8s cluster with [Kubevirt](https://kubevirt.io) preferably v0.23.0 (last tested version).


### changes to cr file

```yaml
server_vm:
  dedicatedcpuplacement: false # cluster would need have the CPUManager feature enabled
  sockets: 1
  cores: 2
  threads: 1
  image: kubevirt/fedora-cloud-container-disk-demo:latest # your image must've ethtool installed if enabling multiqueue
  limits:
    memory: 4Gi
  requests:
    memory: 4Gi
  network:
    front_end: bridge # or masquerade
    multiqueue:
      enabled: false # if set to true, highly recommend to set selinux to permissive on the nodes where the vms would be scheduled
      queues: 0 # must be given if enabled is set to true and ideally should be set to vcpus ideally so sockets*threads*cores, your image must've ethtool installed
  extra_options:
    - none
    #- hostpassthrough
client_vm:
  dedicatedcpuplacement: false # cluster would need have the CPUManager feature enabled
  sockets: 1
  cores: 2
  threads: 1
  image: kubevirt/fedora-cloud-container-disk-demo:latest # your image must've ethtool installed if enabling multiqueue
  limits:
    memory: 4Gi
  requests:
    memory: 4Gi
  network:
    front_end: bridge # or masquerade
    multiqueue:
      enabled: false # if set to true, highly recommend to set selinux to permissive on the nodes where the vms would be scheduled
      queues: 0 # must be given if enabled is set to true and ideally should be set to vcpus ideally so sockets*threads*cores, your image must've ethtool installed
  extra_options:
    - none
    #- hostpassthrough
```

The above is the additional changes required to run uperf in vms.
Currently we only support images that can be used as [containerDisk](https://kubevirt.io/user-guide/docs/latest/creating-virtual-machines/disks-and-volumes.html#containerdisk).

You can easily make your own container-disk-image as follows by downloading your qcow2 image of choice.
You can then make changes to your qcow2 image as needed using virt-customize.

```bash
cat << END > Dockerfile
FROM scratch
ADD <yourqcow2image>.qcow2 /disk/
END

podman build -t <imageurl> .
podman push <imageurl>
```

You can either access results by indexing them directly or by accessing the console.
The results are stored in /tmp/ directory


### Dashboard example

Using the Elasticsearch storage describe above, we can build dashboards like the below.

![UPerf Dashboard](https://i.imgur.com/gSVZ9MX.png)

To reuse the dashboard above, use the json [here](https://github.com/cloud-bulldozer/arsenal/tree/master/uperf/grafana)

Additionally, by default we will utilize the `uperf-results` index for Elasticsearch.
