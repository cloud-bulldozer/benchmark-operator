# Uperf

[Uperf](http://uperf.org/) is a network performance tool

## Running UPerf

Given that you followed instructions to deploy operator,
you can modify [cr.yaml](../resources/crds/ripsaw_v1alpha1_uperf_cr.yaml)

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: uperf-benchmark
  namespace: my-ripsaw
spec:
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
      runtime_class: class_name
      hostnetwork: false
      networkpolicy: false
      pin: false
      kind: pod
      pin_server: "node-0"
      pin_client: "node-1"
      multus:
        enabled: false
      samples: 1
      pair: 1
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

`client_resources` and `server_resources` will create uperf client's and server's containers with the given k8s compute resources respectively [k8s resources](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/)

`serviceip` will place the uperf server behind a K8s [Service](https://kubernetes.io/docs/concepts/services-networking/service/)

`runtime_class` If this is set, the benchmark-operator will apply the runtime_class to the podSpec runtimeClassName.

*Note:* `runtime_class` has only been tested with Kata containers. Only include `runtime_class` if using Kata containers.

`hostnetwork` will test the performance of the node the pod will run on.

`networkpolicy` will create a simple networkpolicy for ingress

`pin` will allow the benchmark runner place nodes on specific nodes, using the `hostname` label.

`pin_server` what node to pin the server pod to.

`pin_client` what node to pin the client pod to.

`multus[1]` Configure our pods to use multus.

`samples` how many times to run the tests. For example

[1] https://github.com/intel/multus-cni/tree/master/examples

```yaml
      samples: 3
      pair: 1
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
      pair: 1
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

Once done creating/editing the resource file, you can run it by:

```bash
# kubectl apply -f resources/crds/ripsaw_v1alpha1_uperf_cr.yaml # if edited the original one
# kubectl apply -f <path_to_file> # if created a new cr file
```

## Running Uperf in VMs through kubevirt/cnv [Preview]
Note: this is currently in preview mode.


### Pre-requisites

You must have configured your k8s cluster with [Kubevirt](https://kubevirt.io) preferably v0.23.0 (last tested version).


### changes to cr file

```yaml
server_vm:
  dedicatedcpuplacement: false # cluster would need have the CPUManager feature enabled
  sockets: 2
  cores: 1
  threads: 1
  image: kubevirt/fedora-cloud-container-disk-demo:latest # your image must've ethtool installed if enabling multiqueue
  limits:
    memory: 2Gi
  requests:
    memory: 2Gi
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
  sockets: 2
  cores: 1
  threads: 1
  image: kubevirt/fedora-cloud-container-disk-demo:latest # your image must've ethtool installed if enabling multiqueue
  limits:
    memory: 2Gi
  requests:
    memory: 2Gi
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



### Storing results into Elasticsearch

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: example-benchmark
  namespace: my-ripsaw
spec:
  clustername: myk8scluster
  test_user: test_user # user is a key that points to user triggering ripsaw, useful to search results in ES
  elasticsearch:
    server: <es_host>
    port: <es_port>
  workload:
    name: uperf
    args:
      hostnetwork: false
      pin: false
      pin_server: "node-0"
      pin_client: "node-1"
      kind: pod
      samples: 1
      pair: 1
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

The new fields :

`elasticsearch.server` this is the elasticsearch cluster ip you want to send the result data to for long term storage.

`elasticsearch.port` port which elasticsearch is listening, typically `9200`.

`user` provide a user id to the metadata that will be sent to Elasticsearch, this makes finding the results easier.

By default we will utilize the `uperf-results` index for Elasticsearch.

Deploying the above(assuming pairs is set to 1) would result in

```bash
# kubectl get -o wide pods
NAME                                                    READY   STATUS      RESTARTS   AGE     IP             NODE       NOMINATED NODE   READINESS GATES
benchmark-operator-6679867fb7-p2fzb                     2/2     Running     0          6h1m    10.130.0.56    master-2   <none>           <none>
uperf-benchmark-nohost-uperf-client-10.128.1.29-kbw4b   0/1     Completed   0          3h11m   10.129.1.214   master-1   <none>           <none>

```

The first pod is our Operator orchestrating the UPerf workload.

To review the results, `kubectl logs <client>`, the top of the output is
the actual workload that was passed to UPerf (From the values in the custom resource).

Note: If cleanup is not set in the spec file then the client pods will be killed after
600 seconds from it's completion. The server pods will be cleaned up immediately
after client job completes

```
... Trimmed output ...
+-------------------------------------------------- UPerf Results --------------------------------------------------+
Run : 1
Uperf Setup

          hostnetwork : False
          client: 10.129.1.214
          server: 10.128.1.29

UPerf results for :

          test_type: stream
          protocol: tcp
          message_size: 64

UPerf results (bytes/sec):

          min: 0
          max: 75938816
          median: 72580096.0
          average: 63342843.6066
          95th: 75016192.0
+-------------------------------------------------------------------------------------------------------------------+

```

### Dashboard example

Using the Elasticsearch storage describe above, we can build dashboards like the below.

![UPerf Dashboard](https://i.imgur.com/gSVZ9MX.png)

To reuse the dashboard above, use the json [here](https://github.com/cloud-bulldozer/arsenal/tree/master/uperf/grafana)

Additionally, by default we will utilize the `uperf-results` index for Elasticsearch.
