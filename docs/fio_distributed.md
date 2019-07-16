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
      pin: false
      samples: 2
      servers: 2
      pin_server: "master-0"
      jobs: #the list can take any of the values in [write,trim,randread,randwrite.randtrim,rw/readwrite,randrw,trimwrite]
        - read
        - write
      bs:
        - 64k
      numjobs:
        - 1
      iodepth: 4
      runtime: 3
      ramp_time: 1
      filesize: 1
      log_sample_rate: 1000
      storageclass: rook-ceph-block
      storagesize: 5Gi
```
Ripsaw will run the jobs sequentially.

To disable the need for PVs, simply comment out the `storageclass` key.

`pin` and `pin_server` will allow the benchmark runner pick what specific node to run FIO on.

Additionally, fio distributed will default to numjobs:1, and this current cannot be overwritten.

(*Technical Note*: If you are running kube/openshift on VMs make sure the diskimage or volume is preallocated.)

## Indexing in elasticsearch and visualization through Grafana ( Experimental )

### Setup of Elasticsearch and Grafana

You'll need to standup the infrastructure required to index and visualize results.
We are using Elasticsearch as the database, and Grafana for visualizing.

#### Elasticsearch

Currently, we have tested with elasticsearch 7.0.1, so please deploy an elasticsearch instance.
There are are many guides that are quite helpful to deploy elasticsearch, for starters
you can follow the guide to deploy with docker by [elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/7.0/docker.html).

Please note that the <es_index> being referred to here is the es_index you provide in the cr. You'd probably want to call it `fio`.
But we've provided freedom for you to call it something else, which can be helpful if you already have indices starting with `fio`.

Ripsaw will be indexing fio logs to the index `<es_index>-logs` so if es_index is fio, then the index is `<es_index>-logs`.

Ripsaw will be indexing fio result json to the index `<es_index>-result` so if es_index is fio, then the index is `fio-result`.

Once you have verified that you can access the elasticsearch, you'll have to create an index template for fio-logs.
We send fio logs to the index `<es_index>-logs`, the template can be found in [arsenal](https://github.com/cloud-bulldozer/arsenal/blob/master/fio-distributed/elasticsearch/7.0.1/fio-logs.json).
Please replace `<es_index>` in the template with your desired name.

For fio json files, no template is required. However if you're an advanced user of elasticsearch, you can create it and edit its settings.


#### Grafana

Currently for fio-distributed, we have tested with grafana 6.3.0. An useful guide to deploy with docker
is present in [grafana docs](https://grafana.com/docs/installation/docker/#running-a-specific-version-of-grafana).

Once you've set it up, you can import the dashboard from the template in [arsenal](https://github.com/cloud-bulldozer/arsenal/blob/master/fio-distributed/grafana/6.3.0/dashboard.json).

You can then follow instructions to import dashboard like adding the data source following the [grafana docs](https://grafana.com/docs/reference/export_import/#importing-a-dashboard)

Please set the data source to point to the earlier, and the index name should be `<es_index>-logs` given in CR.
The field for timestamp will always be `time_ms` .

### Changes to CR for indexing/visualization

If you'd like to try to experiment with storing results in a pv and have followed
instructions to deploy operator with attached pvc and would like to send results to ES(elasticsearch).
you can instead define a custom resource as follows:

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: example-benchmark
  namespace: my-ripsaw
spec:
  elasticsearch:
    server: <es_host>
    port: <es_port>
    index: <es_index>
  test_user: rht_perf_ci # test_user is just a key that points to user triggering ripsaw, useful to search results in ES
  workload:
    name: "fio_distributed"
    args:
      pin: false
      samples: 2
      servers: 2
      pin_server: "master-0"
      jobs: #the list can take any of the values in [write,trim,randread,randwrite.randtrim,rw/readwrite,randrw,trimwrite]
        - read
        - write
      bs:
        - 64k
      numjobs:
        - 1
      iodepth: 4
      runtime: 3
      ramp_time: 1
      filesize: 1
      log_sample_rate: 1000
      log_sample_rate: 1000 # provide only if job is seq or rand
```
