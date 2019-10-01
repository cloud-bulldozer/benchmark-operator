# hammerdb

[hammerdb](https://www.hammerdb.com/) is a performance test kit for various databases. For now it will be used in this operator for MS-SQL databases exclusively.

## Running hammerdb

Given that you followed instructions to deploy operator,
you can modify [cr.yaml](../resources/crds/ripsaw_v1alpha1_hammerdb_cr.yaml) to your needs.

The pgbench workload needs to be pointed at an existing MS-SQL databases via the CR file.

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

Once done creating/editing the resource file, you can run it by:

```bash
# kubectl apply -f <path_to_cr_file>
```

