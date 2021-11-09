# pgbench

[pgbench](https://www.postgresql.org/docs/10/pgbench.html) is a performance test kit for PostgreSQL.

## Running pgbench

Given that you followed instructions to deploy operator,
you can modify [cr.yaml](../config/samples/pgbench/cr.yaml) to your needs.

The pgbench workload needs to be pointed at one or more existing PostgreSQL databases via the CR file.

An example CR might look like this

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: pgbench-benchmark
  namespace: benchmark-operator
spec:
  workload:
    name: "pgbench"
    args:

      ## Standard pgbench command options. See pgbench(1).
      # Note: clients is provided as a list of client counts to iterate through in multiple tests.
      #       clients must be a multiple of threads, not the other way around.
      clients:
        - 2
        - 4
        - 8
      threads: 2
      # Notes: 'transactions' and 'run_time' are mutually exclusive command flags
      #        'transactions' will supersede 'run_time'
      #        'run_time' is defined in seconds
      transactions: 10
      run_time:
      scaling_factor: 1
      # String of other pgbench benchmark command flags not defined above
      # to pass to the benchmark clients
      cmd_flags: ''
      # String of other pgbench init command flags to pass to the pgbench clients
      init_cmd_flags: ''

      ## Ripsaw-specific options
      samples: 1
      # num_databases_pattern takes a pattern definition, one of:
      # 'add1' (1,2,3,...), 'add2' (2,4,6,...), 'log2' (1,2,4,8,...), or 'all'
      # The default if left blank or undefined is 'all'
      num_databases_pattern: 'all'

      ## List of databases to test
      # Note: 'databases' below is a list structures to identify multiple
      #       databases against which benchmarks tests will be run
      databases:
        - host:  # hostname or IP
          user:
          # FIXME: Get passwords other than by plain text here
          password:
          db_name:
          # port will default to 5432 if left blank or undefined
          port:  
          # pin_node is an optional kubernetes hostname to which the pgbench pod will be pinned
          pin_node:
```

The `num_databases_pattern` feature allows you to ramp up the size of the test against the list of databases.

The default of `all` will simply set a single list value equal to the total number of entries in the `databases` list, and so it will perform one outer-loop run against all listed databases simulaneously.

The `add1` and `add2` values will create lists of total number of databases under test. For `add1`, the outer loop will test against 1 database, then 2 databases, then 3, then 4, and so on. For `add2` it will do the same with only even numbers, testing 2 databases, then 4, then 6, and so on.

The `log2` value will increment through a set of values on a log2 scale up to the total number of databases in the list, thus testing 1 database, then 2, then 4, then 8, and so on.

Note that the `add2` and `log2` values may not end up testing 100% of the databases listed, since `add2` will always end on an even number and `log2` will always end on the highest integer on the log2 curve up to the total number of databases (i.e., if you provide 100 databases in the list, the last `log2` test will be against 64 databases since the next log2 value would be 128)

The `runtime_class` option can be set to specify an optional
runtime_class to the podSpec runtimeClassName.  This is primarily
intended for Kata containers.

The option `annotations` can be set to apply the specified
annotations to the pod metadata.

Once done creating/editing the resource file, you can run it by:

```bash
# kubectl apply -f <path_to_cr_file>
```

Output from the script is normalized and reported in the logs of each client pod. For example:

```
+-------------------------------------------------- PGBench Results --------------------------------------------------+
PGBench version: pgbench (PostgreSQL) 9.2.24

UUID: 71a41d72-d927-5c38-af61-ef6697acc894
Run: 1

Database: 10.129.0.115/cidb

PGBench run info:
          transaction_type:  TPC-B (sort of)
          scaling_factor:  1
          query_mode:  simple
          number_of_clients:  1
          number_of_threads:  1
          duration:  5 s

TPS report:
          number_of_transactions_actually_processed:  1729
          tps_incl_con_est: 345.752908
          tps_excl_con_est: 346.844557

+-------------------------------------------------------------------------------------------------------------------+
```

## Storing results into Elasticsearch

The pgbench workload is executed via a wrapper script provided by the [SNAFU](https://github.com/cloud-bulldozer/snafu) repo. This wrapper includes logic to normalize the benchmark output and upload it into Elasticsearch for indexing.

In order to index results, the CR file will need to be updated with the required variables.

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: pgbench-benchmark
  namespace: ripsaw
spec:
  clustername: myk8scluster
  # An aribitrary user name to be stored with the results
  test_user: milton
  # My elasticsearch server information
  elasticsearch:
    url: "htttp://my.elasticsearch.server:9200"
  workload:
    name: "pgbench"
    args:
      clients:
        - 2
        - 4
        - 6
        - 8
      threads: 2
      run_time: 500
      scaling_factor: 100
      cmd_flags: ''
      init_cmd_flags: ''
      samples: 3
      num_databases_pattern: 'all'
      databases:
        - host: my.postgres.host
          user: myuser
          password: mypassword
          db_name: mydbname
          port: 5432
          pin_node: my.pin.node
```
