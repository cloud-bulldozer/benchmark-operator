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
  namespace: my-ripsaw
spec:
  elasticsearch:
    server: "http://es-instance.com:9200"
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

