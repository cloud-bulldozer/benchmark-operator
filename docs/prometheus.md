# Collecting Prometheus Data

How To:
* [What is it](#what-is-it)
* [Configuring](#configuring)

# What is it

The ability to capture prometheus data during a benchmark run was added to the [Benchmark-wrapper](https://github.com/cloud-bulldozer/benchmark-wrapper). 
To enable this functionality and pass prometheus data to an Elasticsearch server the workload CR must be appropriately configured.


# Configuring

To enable this functionality a few variables must be set in the workload CR file.

```
prometheus:
  es_server: the elasticsearch server to upload to
  es_port: the elasticsearch server port
  prom_url: the prometheus URL
  prom_token: a valid access token for prometheus
  es_parallel: enable parallel uploads to elasticsearch
```

The prometheus token can be obtained by running the following.

```
$ oc -n openshift-monitoring sa get-token prometheus-k8s
```

Enabling prometheus data capture may greatly increase the load on the Elasticsearch server that is being used. Please be aware and have the
Elasticsearch instance sized appropriately.

*NOTE:* The prometheus Elasticsearch server may be the same *OR* different than the Elasticsearch server used for the benchmark data.

Example CR with prometheus uploads enabled

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
  prometheus:
    es_server: my.other.es.server
    es_port: 8080
    prom_url: my.prom.server:9100
    prom_token: 0921783409ufsd09752039ufgpods9u750239uge0p34
    es_parallel: true
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
