# Indexing to Elasticsearch

How To:
* [What is it](#what-is-it)
* [Configuring](#configuring)

# What is it

Most workloads are configured to send the benchmark data to Elasticsearch if given the proper information.

# Configuring

To enable this functionality a few variables must be set in the workload CR file.

```
elasticsearch:
  server: the elasticsearch server to upload to
  port: the elasticsearch server port
  parallel: enable parallel uploads to elasticsearch [default: false]
  index_name: the index name to use [default: workload defined]
```

*NOTE:* The only required parameters if using elasticsearch and the port and server. The others are optional and will be defaulted if not provided.
Additionally, enabling parallel uploading may greatly impact Elasticsearch server performance. Ensure your environment is configured to handle the
increased load before enabling

Example CR with elasticsearch information provided

```
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: smallfile-benchmark
  namespace: my-ripsaw
spec:
  test_user: homer_simpson
  clustername: test_ci
  elasticsearch:
    server: my.es.server
    port: 8080
    index_name: ripsaw-smallfile
  metadata:
    collection: true
  workload:
    name: smallfile
    args:
      clients: 2
      operation: ["create", "read", "append", "delete"]
      threads: 1
      file_size: 0
      files: 100000
```
