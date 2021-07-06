# hammerdb

[hammerdb](https://www.hammerdb.com/) is a performance test kit for various databases. For now it will be used in this operator for MS-SQL databases exclusively.

## Running hammerdb

Given that you followed instructions to deploy operator,
you can modify [cr.yaml](../resources/crds/hammerdb_crds/ripsaw_v1alpha1_hammerdb_cr.yaml) to your needs.

The hammerdb workload needs to be pointed at an existing [MSSQL](../resources/crds/hammerdb_crds/mssql/ripsaw_v1alpha1_hammerdb_mssql_cr.yaml), [MARIADB](../resources/crds/hammerdb_crds/mariadb/ripsaw_v1alpha1_hammerdb_mariadb_cr.yaml), [POSTGRES](../resources/crds/hammerdb_crds/postgres/ripsaw_v1alpha1_hammerdb_postgres_cr.yaml) database via the CR file.

An example CR might look like this

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: hammerdb-benchmark
  namespace: my-ripsaw
spec:
  elasticsearch:
    url: http://my.elasticsearch.server:80
    index_name: ripsaw-hammerdb
  metadata:
    collection: false
  workload:
    name: hammerdb
    args:
      #image: quay.io/user/hammerdb:latest # add custom hammerdb image
      pin: false # true for nodeSelector
      pin_client: "node1"
      resources: false # true for resources requests/limits
      requests_cpu: 200m
      requests_memory: 100Mi
      limits_cpu: 4
      limits_memory: 16Gi
      db_type: "mssql"
      timed_test: true
      test_type: "tpc-c"
      db_init: true # true only for first run to build schema
      db_benchmark: true
      db_server: "mssql-deployment.mssql-db"
      db_port: "1433"
      db_warehouses: 1
      db_num_workers: 1
      db_user: "SA"
      db_pass: "s3curePasswordString"
      db_name: "tpcc"
      transactions: 10000
      raiseerror: "false"
      keyandthink: "false"
      driver: "timed"
      rampup: 1
      runtime: 1
      allwarehouse: false
      timeprofile: false
      async_scale: false
      async_client: 10
      async_verbose: false
      async_delay: 1000
      samples: 1
      # database specific variables
      # mssql:
      db_mssql_tcp: "true"
      db_mssql_azure: "false"
      db_mssql_authentication: "windows"
      db_mssql_linux_authent: "sql"
      db_mssql_odbc_driver: "ODBC Driver 13 for SQL Server"
      db_mssql_linux_odbc: "ODBC Driver 17 for SQL Server"
      db_mssql_imdb: "false"
      db_mssql_bucket: 1
      db_mssql_durability: "SCHEMA_AND_DATA"
      db_mssql_checkpoint: "false"
      # mariadb:
      db_mysql_storage_engine: "innodb"
      db_mysql_partition: "false"
      db_mysql_socket: "/var/lib/mysql/mysql.sock"
      # postgresql
      db_postgresql_superuser: "SA"
      db_postgresql_superuser_pass: "s3curePasswordString"
      db_postgresql_defaultdbase: "postgres"
      db_postgresql_vacuum: "false"
      db_postgresql_dritasnap: "false"
      db_postgresql_oracompat: "false"
      db_postgresql_storedprocs: "false"
      # ElasticSearch custom fields
      es_custom_field: false
      es_ocp_version: "4.7.0"
      es_cnv_version: "2.6.2"
      es_db_version: "2019"
      es_os_version: "centos8"
      es_kind: "pod"
```
The `pin` feature is `true` for node selector, `pin_node` is the node name

The `resource` feature is `true` for resources configurations: `requests_cpu`, `requests_memory`, `limits_cpu`, `limits_memory`

The `db_type` is the database type: mariadb, pg or mssql

The `db_init` feature determines wether the database has already been initialized `false` or needs to be initialized `true`. If the DB has been used previously to run benchmarks against it, it needs to be set to `false`.

The `db_benchmark` feature used to run the actual benchmark when set to `true`. 

The `db_server` either holds the name or the IP address of the DB server, 

The `db_port` the port on which the DB is accessible. If `db_mssql_tcp` is set to `true` the client will use a TCP connection, if it's set to `false` UDP will be used.

The `db_user` and `db_pass` need to be set identical to the settings on the DB server side. 

The tpcc benchmark which we use can set up an arbitrary number of warehouses between which goods will be transferred in order to simulate a real-world scenario. The higher the number of warehouses is, the more complex and load-heavy the benchmark can get. 
The `db_warehouses` is used to define this number. 
The `db_num_workers` is used to controls the number of virtual users, acting upon the warehouses and the goods in them. This number needs to lesser or equal to the number of warehouses.
* db_warehouses >= db_num_workers: virtual users must be less than or equal to number of warehouses

With `runtime`, `rampup` and `samples` the time for a single run, the rampup time per run and the number of runs can be controlled. 

The `es_custom_field` feature is `true` to enable distribute the following fields to Elastic Search: `es_ocp_version`, `es_cnv_version`, `es_db_version`, `es_os_version`, `es_kind`

There are several options to store database data on Pod, the default one is ephemeral:

HostPath: The data will be stored on a local disk where the OS is placed.

Local: The data will be stored on local disk on separate disk, separate disk from OS. 

PVC: The data will be stored on Container Storage, it's required a Pre-installed Container Storage

MSSQL examples:
[MSSQL ephemeral](../resources/crds/hammerdb_crds/mssql/ripsaw_v1alpha1_hammerdb_mssql_server.yaml),
[MSSQL HostPath](../resources/crds/hammerdb_crds/mssql/ripsaw_v1alpha1_hammerdb_mssql_server_hostpath.yaml),
[MSSQL Local](../resources/crds/hammerdb_crds/mssql/ripsaw_v1alpha1_hammerdb_mssql_server_local.yaml),
[MSSQL PVC](../resources/crds/hammerdb_crds/mssql/ripsaw_v1alpha1_hammerdb_mssql_server_pvc.yaml)

Postgres examples:
[Postgres ephemeral](../resources/crds/hammerdb_crds/postgres/ripsaw_v1alpha1_hammerdb_postgres_server.yaml),
[Postgres HostPath](../resources/crds/hammerdb_crds/postgres/ripsaw_v1alpha1_hammerdb_postgres_server_hostpath.yaml),
[Postgres Local](../resources/crds/hammerdb_crds/postgres/ripsaw_v1alpha1_hammerdb_postgres_server_local.yaml),
[Postgres PVC](../resources/crds/hammerdb_crds/postgres/ripsaw_v1alpha1_hammerdb_postgres_server_pvc.yaml)

Mariadb examples:
[Mariadb ephemeral](../resources/crds/hammerdb_crds/mariadb/ripsaw_v1alpha1_hammerdb_mariadb_server.yaml),
[Mariadb HostPath](../resources/crds/hammerdb_crds/mariadb/ripsaw_v1alpha1_hammerdb_mariadb_server_hostpath.yaml),
[Mariadb Local](../resources/crds/hammerdb_crds/mariadb/ripsaw_v1alpha1_hammerdb_mariadb_server_local.yaml),
[Mariadb PVC](../resources/crds/hammerdb_crds/mariadb/ripsaw_v1alpha1_hammerdb_mariadb_server_pvc.yaml)


The option **runtime_class** can be set to specify an optional
runtime_class to the podSpec runtimeClassName.  This is primarily
intended for Kata containers.

Once done creating/editing the resource file, you can run it by:

```bash
# kubectl apply -f <path_to_cr_file>
```

## Running hammerdb in VMs through kubevirt/cnv [Working]


### changes to cr file

```yaml
      kind: vm
      client_vm:
        dedicatedcpuplacement: false
        sockets: 1
        cores: 2
        threads: 1
        image: kubevirt/fedora-cloud-container-disk-demo:latest
        requests:
          memory: 100Mi
        limits:
          memory: 16Gi # at least 16Gi for VM
        network:
          front_end: bridge # or masquerade
          multiqueue:
            enabled: false # if set to true, highly recommend to set selinux to permissive on the nodes where the vms would be scheduled
            queues: 0 # must be given if enabled is set to true and ideally should be set to vcpus ideally so sockets*threads*cores, your image must've ethtool installed
        extra_options:
          - none
          #- hostpassthrough
-       ## OCS PVC
        pvc: false # enable for OCS PVC
        pvc_storageclass: ocs-storagecluster-ceph-rbd
        pvc_pvcaccessmode: ReadWriteMany
        pvc_pvcvolumemode: Block
        pvc_storagesize: 10Gi
        ## HostPath - Configuring SELinux on cluster workers
        hostpath: false # enable for hostPath
        hostpath_path: /var/tmp/disk.img
        hostpath_storagesize: 10Gi
```

The above is the additional changes required to run hammerdb in vms.

There several options to store database data on VM, the default on is ephemeral:

PVC: The data will be stored on Container Storage, it's required a Pre-installed Container Storage

The `pvc` feature is `true` for enabling container storage PVC on VM, 
there several parameters that must be configured: 
`pvc_storageclass` for pvc storage class (`kubectl get sc`)
`pvc_pvcaccessmode` can be one of ReadWriteOnce,ReadOnlyMany,ReadWriteMany Default: ReadWriteOnce
`pvc_pvcvolumemode` can be one of Filesystem,Block Default: Filesystem
`pvc_storagesize` the PVC storage size

HostPath: The data will be stored on the local disk where the OS is placed.

The `hostpath` feature is `true` for enabling HostPath on VM, 
there several parameters that must be configured: 
`hostpath_path` The image path to hold the hostPath 
`hostpath_storagesize` the HostPath storage size

examples:
[MSSQL](../resources/crds/hammerdb_crds/mssql/ripsaw_v1alpha1_hammerdb_mssql_vm.yaml),
[Postgres](../resources/crds/hammerdb_crds/postgres/ripsaw_v1alpha1_hammerdb_postgres_vm.yaml),
[Mariadb](../resources/crds/hammerdb_crds/mariadb/ripsaw_v1alpha1_hammerdb_mariadb_vm.yaml),


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
You can console into VM by running `virtctl console vmi_name`