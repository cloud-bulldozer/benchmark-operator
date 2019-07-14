# pgbench

[pgbench](https://www.postgresql.org/docs/10/pgbench.html) is a performance test kit for PostgreSQL.

## Running pgbench

Given that you followed instructions to deploy operator,
you can modify [cr.yaml](../resources/crds/ripsaw_v1alpha1_pgbench_cr.yaml) to your needs.

The pgbench workload needs to be pointed at one or more existing PostgreSQL databases via the CR file.

An example CR might look like this

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: pgbench-benchmark
  namespace: my-ripsaw
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
      # TODO: test_sequential not yet implemented; all tests are currently pseudo-parallel
      # Tests of multiple databases will be done in parallel unless
      # test_sequential is set to True
      #test_sequential: False

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

Once done creating/editing the resource file, you can run it by:

```bash
# kubectl apply -f <path_to_cr_file>
```
