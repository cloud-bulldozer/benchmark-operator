# Collecting Prometheus Data

How To:
- [Collecting Prometheus Data](#collecting-prometheus-data)
- [What is it](#what-is-it)
- [Configuring](#configuring)

# What is it

The ability to capture prometheus data during a benchmark run was added to the [Benchmark-wrapper](https://github.com/cloud-bulldozer/benchmark-wrapper). 
To enable this functionality and pass prometheus data to an Elasticsearch server the workload CR must be appropriately configured.


# Configuring

To enable this functionality a few variables must be set in the workload CR file.

```
prometheus:
  es_url: the elasticsearch server to upload to
  prom_url: the prometheus URL
  prom_token: a valid access token for prometheus
  es_parallel: enable parallel uploads to elasticsearch
```

**Note**: Full URL format required for ElasticSearch. i.e. http://myesinstance.domain.com:9200

The prometheus token can be obtained by running the following.

```
$ oc -n openshift-monitoring sa get-token prometheus-k8s
```

Enabling prometheus data capture may greatly increase the load on the Elasticsearch server that is being used. Please be aware and have the
Elasticsearch instance sized appropriately.

*NOTE:* The prometheus Elasticsearch server may be the same *OR* different than the Elasticsearch server used for the benchmark data.

Example CR with prometheus uploads enabled

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: smallfile-benchmark
  namespace: ripsaw-system
spec:
  test_user: homer_simpson
  clustername: test_ci
  elasticsearch:
    url: "http://my.es.server:9200"
    index_name: ripsaw-smallfile
  prometheus:
    es_url: "http://my.other.es.server:80"
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

**Note**: It's possible to index documents in an authenticated ES instance using the notation `http(s)://[username]:[password]@[address]:[port]` in the url parameter.
