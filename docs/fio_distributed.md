# FIO Distributed

[FIO](https://github.com/axboe/fio) has a native mechanism to run multiple servers concurrently.

This workload will launch N number of FIO Servers and a single FIO Client which will kick off the
workload.

## Running Distributed FIO

Build your CR for Distributed FIO

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: fio-benchmark
  namespace: my-ripsaw
spec:
  workload:
    name: "fio_distributed"
    args:
      samples: 2
      servers: 2
      pin_server: ''
      jobs: #the list can take any of the values in [write,trim,randread,randwrite.randtrim,rw/readwrite,randrw,trimwrite]
        - read
        - write
      bs:
        - 64Ki
      numjobs:
        - 1
      iodepth: 4
      runtime: 60
      ramp_time: 5
      filesize: 2Gi
      log_sample_rate: 1000
      storageclass: rook-ceph-block
      storagesize: 5Gi
#######################################
#  EXPERT AREA - MODIFY WITH CAUTION  #
#######################################
#  global_overrides:
#    - "key=value"
  job_params:
    - jobname_match: "w"
      params:
        - "fsync_on_close=1"
        - "create_on_open=1"
    - jobname_match: "rw"
      params:
        - "rwmixread=50"
    - jobname_match: "readwrite"
      params:
        - "rwmixread=50"
#    - jobname_match: "<search_string>"
#      params:
#        - "key=value"
```
Ripsaw will run the provided `jobs` sequentially.

To disable the need for PVs, simply comment out or exclude the `storageclass` key.

Setting `pin_server` will allow the benchmark runner to pick what specific node to run all FIO server pods on.

(*Technical Note*: If you are running kube/openshift on VMs make sure the diskimage or volume is preallocated.)

## Indexing in elasticsearch and visualization through Grafana

### Setup of Elasticsearch and Grafana

You'll need to standup the infrastructure required to index and visualize results.
We are using Elasticsearch as the database, and Grafana for visualizing.

#### Elasticsearch

Currently, we have tested with elasticsearch 7.0.1, so please deploy an elasticsearch instance.
There are are many guides that are quite helpful to deploy elasticsearch, for starters
you can follow the guide to deploy with docker by [elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/7.0/docker.html).

Once you have verified that you can access the elasticsearch, you'll have to create an index template for ripsaw-fio-logs.

We send fio logs to the index `ripsaw-fio-logs`, the template can be found in [arsenal](https://github.com/cloud-bulldozer/arsenal/blob/master/fio-distributed/elasticsearch/7.0.1/fio-logs.json).

Ripsaw will be indexing the fio result json to the index `ripsaw-fio-result`. For this, no template is required. However if you're an advanced user of elasticsearch, you can create it and edit its settings.


#### Grafana

Currently for fio-distributed, we have tested with grafana 6.3.0. An useful guide to deploy with docker
is present in [grafana docs](https://grafana.com/docs/installation/docker/#running-a-specific-version-of-grafana).

Once you've set it up, you can import the dashboard from the template in [arsenal](https://github.com/cloud-bulldozer/arsenal/blob/master/fio-distributed/grafana/6.3.0/dashboard.json).

You can then follow instructions to import dashboard like adding the data source following the [grafana docs](https://grafana.com/docs/reference/export_import/#importing-a-dashboard)

Please set the data source to point to the earlier, and the index name should be `ripsaw-fio-logs`.
The field for timestamp will always be `time_ms` .

### Changes to CR for indexing/visualization

If you'd like to try to experiment with storing results in a pv and have followed
instructions to deploy operator with attached pvc and would like to send results to ES (elasticsearch).
you can instead define a custom resource as follows:

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: fio-benchmark
  namespace: my-ripsaw
spec:
  elasticsearch:
    server: my.elasticsearch.server
    port: 9200
  test_user: ripsaw
  workload:
    name: "fio_distributed"
    args:
      samples: 2
      servers: 2
      pin_server: ''
      jobs: #the list can take any of the values in [write,trim,randread,randwrite.randtrim,rw/readwrite,randrw,trimwrite]
        - read
        - write
      bs:
        - 64Ki
      numjobs:
        - 1
      iodepth: 4
      runtime: 60
      ramp_time: 5
      filesize: 2Gi
      log_sample_rate: 1000
      storageclass: rook-ceph-block
      storagesize: 5Gi
#######################################
#  EXPERT AREA - MODIFY WITH CAUTION  #
#######################################
#  global_overrides:
#    - "key=value"
  job_params:
    - jobname_match: "w"
      params:
        - "fsync_on_close=1"
        - "create_on_open=1"
    - jobname_match: "rw"
      params:
        - "rwmixread=50"
    - jobname_match: "readwrite"
      params:
        - "rwmixread=50"
#    - jobname_match: "<search_string>"
#      params:
#        - "key=value"
```

> Note: The `test_user` value is arbitrary metadata for your indexing needs, and if left undefined it will default to `ripsaw`.
