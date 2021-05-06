# hammerdb

[hammerdb](https://www.hammerdb.com/) is a performance test kit for various databases. For now it will be used in this operator for MS-SQL databases exclusively.

## Running hammerdb

Given that you followed instructions to deploy operator,
you can modify [cr.yaml](../resources/crds/hammerdb_crds/ripsaw_v1alpha1_hammerdb_cr.yaml) to your needs.

The pgbench workload needs to be pointed at an existing [MSSQL](../resources/crds/hammerdb_crds/mssql), [MARIADB](../resources/crds/hammerdb_crds/mariadb), [POSTGRES](../resources/crds/hammerdb_crds/postgres) databases via the CR file.

An example CR might look like this

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: hammerdb
  namespace: my-ripsaw
spec:
  workload:
    name: "hammerdb"
    args:
      db_init: false
      db_benchmark: true
      db_server: "mssql-deployment.sql-server"
      db_port: "1443"
      db_tcp: "true"
      db_user: "SA"
      db_pass: "s3curePasswordString"
      db_warehouses: 1
      db_num_workers: 1
      transactions: 20000
      runtime: 1
      rampup: 1
      samples: 1
```

The `db_init` feature determines wether the database has already been initialized (false) or needs to be initialized (true). If the DB has been used previously to run benchmarks against it, it needs to be set to `false`.

The `db_benchmark` feature is used to run the actual benchmark when set to true. `db_server` either holds the name or the IP address of the DB server, `db_port` the port on which the DB is accessible. If `db_tcp` is set to true the client will use a TCP connection, if it's set to `false` UDP will be used.

`db_user` and `db_pass` need to be set identical to the settings on the DB server side. 

The tpcc benchmark which we use can set up an arbitrary number of warehouses between which goods will be transferred in order to simulate a real-world scenario. The higher the number of warehouses is, the more complex and load-heavy the benchmark can get. `db_warehouses` is used to define this number. 
`db_num_workers` controls the number of virtual users, acting upon the warehouses and the goods in them. This number needs to lesser or equal to the number of warehouses.

With `runtime`, `rampup` and `samples` the time for a single run, the rampup time per run and the number of runs can be controlled. 

The option **runtime_class** can be set to specify an optional
runtime_class to the podSpec runtimeClassName.  This is primarily
intended for Kata containers.

Once done creating/editing the resource file, you can run it by:

```bash
# kubectl apply -f <path_to_cr_file>
```

## Running hammerdb in VMs through kubevirt/cnv [Preview]
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

The above is the additional changes required to run hammerdb in vms.
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