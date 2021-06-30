# stressng

[stressng](https://wiki.ubuntu.com/Kernel/Reference/stress-ng) is a performance test tool to stress various system resources like the CPU, memory and the I/O subsystem.

## Running stressng

Given that you followed instructions to deploy operator,
you can modify [cr.yaml](../resources/crds/ripsaw_v1alpha1_stressng.yaml) to your needs.

The optional argument **runtime_class** can be set to specify an
optional runtime_class to the podSpec runtimeClassName.  This is
primarily intended for Kata containers.

An example CR might look like this

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: stressng
  namespace: ripsaw-system
spec:
  elasticsearch:
    url: "http://es-instance.com:9200"
    index_name: ripsaw-stressng
  metadata:
    collection: true
  workload:
    name: "stressng"
    args:
      # general options
      runtype: "parallel"
      timeout: "30"
      instances: 1
      # nodeselector: 
      # cpu stressor options
      cpu_stressors: "1"
      cpu_percentage: "100"
      # vm stressor option
      vm_stressors: "1"
      vm_bytes: "128M"
      # mem stressor options
      mem_stressors: "1"

```

The stressng benchmark is divided into 3 subsystems, driven by so-called stressors. In the above example we have cpu stressors, virtual memory (vm) stressors and memory stressors. They are running in a parallel fashion, but could also run sequentially. 
Looking at the stressors individually:

| field name            | description                                                   |
|-----------------------|---------------------------------------------------------------|
| runtype               | parallel or sequential                                        |
| timeout               | time for the stressors to run                                 | 
| instances             | number of instances (pods) to run                             |
| nodeselector          | label for nodes on which the stressor pods will run           |
| cpu_stressors         | number of cpu stressors                                       |
| cpu_percentage        | percentage at which the stressor will run, e.g. 70% of a CPU  |
| vm_stressors          | number of vm stressors                                        |
| vm_bytes              | amount of memory the vm stressor will use                     |
| mem_stressors         | number of memory stressors                                    | 

Once done creating/editing the resource file, you can run it by:

```bash
# kubectl apply -f <path_to_cr_file>
```

## Running stressng in VMs through kubevirt/cnv [Preview]
Note: this is currently in preview mode.


### changes to cr file

```yaml
      kind: vm
      client_vm:
        dedicatedcpuplacement: false
        sockets: 1
        cores: 2
        threads: 1
        image: kubevirt/fedora-cloud-container-disk-demo:latest
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

The above is the additional changes required to run stressng in vms.
Currently, we only support images that can be used as [containerDisk](https://docs.openshift.com/container-platform/4.6/virt/virtual_machines/virtual_disks/virt-using-container-disks-with-vms.html#virt-preparing-container-disk-for-vms_virt-using-container-disks-with-vms).

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
