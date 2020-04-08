# Pre-run init containers

Sometimes we need to prepare the environment before triggering a workload with some actions such as dropping caches, creating a directory structure or execute a script.

Several Ripsaw's workloads have a customizable [initContainer](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/) that will be launched before the actual workload.

Ripsaw allows to customize the command and image launched by this initContainer through the variables `pre_run_cmd` and `pre_run_image`. Where `pre_run_cmd` configures the
command to execute in the initContainer and `pre_run_image` overrides the initContainer container image, which by default corresponds with the workload image.

## Init volumes and options

The pre-run initContainer mounts the same data volumes as the parent workloads. So it will be able to access to the same data.
Setting `privileged_pre_run` to true executes re-run initContainer as privileged, which may be useful to perform privileged actions such as configuring or drop caches or access hostPath volumes data.

## Workloads using pre-run initContainers

We can make use of pre-run initContainers in the following workloads:

- Fio: pre-run is executed in each Fio server pod.

## How it works

The pre-run initContainer executes from a shell the command given by the variable `pre_run_cmd`, it defaults to a simple `exit 0` if this variable is not configured.
The command is executed from a container image given by the variable `pre_run_image` which defaults to the workload image, in the example below `quay.io/cloud-bulldozer/fio:latest`.

The following code snippet has been extracted from the Fio server job template:

```yaml
      initContainers:
      - name: pre-run
        image: {{ pre_run_image|default("quay.io/cloud-bulldozer/fio:latest", true) }}
        command: ["/bin/sh"]
        args: ["-c", "{{ pre_run_cmd|default("exit 0", true) }}"]
{% if fiod.storageclass is defined or hostpath is defined %}
        volumeMounts:
        - name: data-volume
          mountPath: "{{ fio_path }}"
{% endif %}
        securityContext:
          privileged: {{ privileged_pre_run|default(false, true) }}
```

The following example triggers an initContainer to drop caches before running the actual Fio workload. Note the value of the `privileged_pre_run` flag.


```yaml
piVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: fio-benchmark
  namespace: my-ripsaw
spec:
  elasticsearch:
    server: "marquez.perf.lab.eng.rdu2.redhat.com"
    port: 9200
  metadata_collection: true
  privileged_pre_run: true
  pre_run_cmd: "echo 3 > /proc/sys/vm/drop_caches"
  workload:
    name: "fio_distributed"
    args:
      samples: 1
      servers: 2
      jobs:
        - write
        - read
      bs:
        - 4KiB
      numjobs:
        - 1
      iodepth: 2
      read_runtime: 3
      read_ramp_time: 1
      filesize: 10MiB
      log_sample_rate: 1000
    - jobname_match: w
      params:
        - fsync_on_close=1
```

It's also possible to introduce more than one command in the pre-run initContainer, there must be a semicolon at the end of each command as shown below.

```yaml
  pre_run_cmd: |
    mkdir -p /my/directory/struct;
    for f in my list of files; do
      cat /dev/zero | dd iflag=fullblock of=/my/directory/struct/${f} bs=1024K count=10;
    done;
    sync
```

