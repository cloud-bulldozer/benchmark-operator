# Indexing to Elasticsearch

How To:
- [Indexing to Elasticsearch](#indexing-to-elasticsearch)
- [What is it](#what-is-it)
- [Enabling Collection](#enabling-collection)
    - [Benchmark Data](#benchmark-data)
    - [Prometheus Data](#prometheus-data)
      - [Retrieving Openshift Prometheus info](#retrieving-openshift-prometheus-info)
- [Extending Prometheus Collection](#extending-prometheus-collection)
    - [Elasticsearch-Prometheus Data Model](#elasticsearch-prometheus-data-model)
    - [Explaining Workload Include Files](#explaining-workload-include-files)
    - [Adding Prometheus collection trigger](#adding-prometheus-collection-trigger)


# What is it

Elasticsearch is a distributed NoSQL database that allows users to quick search and analyze data. After execution of
each benchmark benchmark-operator(via benchmark-wrapper) collects test data and indexes it into Elasticsearch. Besides 
initial setup and deployment of the elasticsearch cluster, workloads are configured to send the benchmark data to Elasticsearch
automatically, when users provide the proper information. 

In addition to storing benchmark data, we are able to capture Openshift Prometheus data by providing the Prom URL and access token.
With the collection of prom data, users gain the benefit of capturing a holistic view of loads on the entire system and 
ability to analyze resource usage based test constraints. 

Current supported ES + Prometheus integrated workloads:

| Workload                       | Status                 |
| ------------------------------ | ---------------------- |
| [UPerf](docs/uperf.md)         | Not Supported    |
| [Iperf3](docs/iperf.md)        | Not Supported    |
| [fio](docs/fio_distributed.md) | Supported        |
| [Sysbench](docs/sysbench.md)   | Not Supported    |
| [YCSB](docs/ycsb.md)           | Not Supported    |
| [Byowl](docs/byowl.md)         | Not Supported    |
| [Pgbench](docs/pgbench.md)     | Not Supported    | 
| [Smallfile](docs/smallfile.md) | Not Supported    |
| [fs-drift](docs/fs-drift.md)   | Not Supported    |
| [hammerdb](docs/hammerdb.md)   | Not Supported    |
| [Service Mesh](docs/servicemesh.md) | Not Supported    | 
| [Vegeta](docs/vegeta.md)       | Not Supported    | 
| [Scale Openshift](docs/scale_openshift.md) | Not Supported    |
| [stressng](docs/stressng.md)   | Not Supported    | 
| [kube-burner](docs/kube-burner.md)  | Not Supported    | 
| [cyclictest](docs/cyclictest.md)  | Not Supported    | 
| [oslat](docs/oslat.md)         | Not Supported    | 

# Enabling Collection


### Benchmark Data
To enable this functionality a few variables must be set in the workload CR file.

```
elasticsearch:
  server: the elasticsearch server URL to upload to
  parallel: enable parallel uploads to elasticsearch [default: false]
  index_name: the index name to use [default: workload defined]
  verify_cert: disable elasticsearch certificate verification [default: true]
```

**NOTE**: The ElasticSearch URL MUST BE in the format http(s)://[address]:[port]

In addition to the above, the following parameters can be also specified at the `spec` level to improve indexed documents metadata.
- `test_user` user is a key that points to user triggering ripsaw, useful to search results in ES. Defaults to *ripsaw*.
- `clustername` an arbitrary name for your system under test (SUT) that can aid indexing.

*NOTE:* The only required parameter if using elasticsearch is the URL server. The others are optional and will be defaulted if not provided.
Additionally, enabling parallel uploading may greatly impact Elasticsearch server performance. Ensure your environment is configured to handle the
increased load before enabling

Example CR with elasticsearch information provided

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: smallfile-benchmark
  namespace: my-ripsaw
spec:
  test_user: homer_simpson
  clustername: test_ci
  elasticsearch:
    server: "http://my.es.server:9200"
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

### Prometheus Data
To enable this functionality we must provide the following parameters to the workload CR file:

```
  prometheus:
    es_server: my.es.server
    es_port: 8080 
    prom_url: http://< URL > 
    prom_token: <token>
    es_parallel: true|false
```

Depending on your infrastructure and desire to store prometheues data separately from your benchmark data, you are able 
to specify the same or different ES server/port from the benchmark data instance. Users are also able to separately 
control whether or not to upload using the parallel indexer. 

It's important to note due to the quantity of data from Promethues we recommend using parallel, as long as your ES 
infrastructure can handle the load. 

Example CR with elasticsearch and prometheus information provided

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
    es_server: my.es.server
    es_port: 8080 
    prom_url: http://< URL > 
    prom_token: <token>
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
   
#### Retrieving Openshift Prometheus info

In order to query Prometheus we must provide the URL and access token. 

It is recommended that users us the internal prometheus service address, which is always the same for every cluster and 
prevents this traffic to go out and in the cluster. (`https://prometheus-k8s.openshift-monitoring.svc.cluster.local:9091`) 

Alternatively, in order to retrieve the external prometheus service address user can do so by executing 
`oc -n openshift-monitoring get routes | grep prometheus`. 

Depending on your environment you either need to setup a service account, with a cluster role of 
cluster-monitoring-view ,or use the Prometheus user account's token. 

Command to setup a service account and retrieve token: 

```
oc create serviceaccount snafu -n my-ripsaw
oc create clusterrolebinding grafana-cluster-monitoring-view --clusterrole=cluster-monitoring-view --serviceaccount=my-ripsaw:snafu
oc sa get-token snafu -n my-ripsaw
```

*NOTE:* User tokens can expire, for long running test it is recommend to either set the necessary permissions 
on the token, or use the Prometheus service account's token.

Command to retrieve prometheus service account's token: 

`oc -n openshift-monitoring sa get-token prometheus-k8s`


# Extending Prometheus Collection 

This section will help contributers to understand and extend collection of the openshift prometheus data for all 
workloads. Below we will explain the data model used for integrating Prometheus data with elasticsearch, explain 
workload include files, and the exact code block to use for triggering prom collection for your workload.
 
### Elasticsearch-Prometheus Data Model

This section will break down the data model used for normalizing Prometheus data for Elasticsearch indexing. 

During collection we execute a prom instance query for all applicable metrics that are listed in the
include file(discussed further in next section). For each query, Prometheus returns a data object containing a list of 
results for the specified metric. Each result object contains two sub-components, 1 the value of the metric at a 
specific time, and metric attributes such as name, instances, device, mode, pod, etc.   

Example Prometheus Instant Query Data Model:
```
{
   "status" : "success",
   "data" : {
      "resultType" : "vector",
      "result" : [
         {
            "metric" : {
               "__name__" : "up",
               "job" : "prometheus",
               "instance" : "localhost:9090"
            },
            "value": [ 1435781451.781, "1" ]
         },
         {
            "metric" : {
               "__name__" : "up",
               "job" : "node",
               "instance" : "localhost:9100"
            },
            "value" : [ 1435781451.781, "0" ]
         }
      ]
   }
}
```

Besides capturing metric values and attributes on each metric, we must add context to each record to aid in analysis
and correlation between metrics. 

For each record we expect that workloads provide the following:

* uuid - universally unique identifier, automatically created by benchmark-operator
* user - gathered from parameters passed from the CR file
* clustername - gathered from parameters passed from the CR file
* startime - sample start time, used for bounding search query
* endtime - sample stop time, used for bounding search query
* sample - indication of sample number, used for statistical analysis of results and filtering
* tool - used to identify which include file to load
* test_config - a dictionary containing the current sample's test parameters. 

*NOTE:* Because test config is dependent upon the specific workload, and due to the risk of overloading fields each tool will 
have its own seperate prometheus collection index, labeled **ripsaw-<tool_name>-prometheus_data**

How workloads provide this information is covered in [Adding Prometheus collection trigger](#adding-prometheus-collection-trigger)

Upon the triggering and successfully execution of the Prometheus query, we combine the results into a normalized structure
that allows for easy indexing and analysis. Below is an example of the overall structure for a normalized result, and 
a example document captured from a previous fio workload.

Normalized ES Data model:
```
"_source": {
    "uuid": <uuid>
    "user": <user>
    "clustername": <clustername>
    "sample": <int>
    "starttime": <datetime> datetime.utcnow().strftime('%s')
    "endtime": <datetime>
    "sample": self.sample,
    "tool": "tool_name",
    "test_config": {...}
    "metric": result["metric"],
    "Date": result[value][0], #timestamp
    "value": result[value][1], #value of metric
    "metric_name": metric_name
    }
```

Example Normalized record from Fio workload:

```
"_source": {
    "metric": {
      "device": "nvme0n1",
      "endpoint": "https",
      "instance": "ip-10-0-133-156.ec2.internal",
      "job": "node-exporter",
      "namespace": "openshift-monitoring",
      "pod": "node-exporter-vjqcj",
      "service": "node-exporter",
      "name": "node_disk_reads_completed_total"
    },
    "Date": "2020-11-20T18:49:47.000000Z",
    "value": 0,
    "metric_name": "Average_Disk_IOPS_Read",
    "uuid": "16278470-ea20-5f0a-b343-542d7bc3c318",
    "user": "acalhoun",
    "cluster_name": "acalhoun-test-bench",
    "starttime": "1605898067",
    "endtime": "1605898189",
    "sample": 4,
    "tool": "fio",
    "test_config": {
      "global": {
        "directory": "/mnt/pvc",
        "filename_format": "f.\\$jobnum.\\$filenum",
        "write_bw_log": "fio",
        "write_iops_log": "fio",
        "write_lat_log": "fio",
        "write_hist_log": "fio",
        "log_avg_msec": "30000",
        "log_hist_msec": "30000",
        "clocksource": "clock_gettime",
        "kb_base": "1000",
        "unit_base": "8",
        "ioengine": "libaio",
        "size": "32GiB",
        "bs": "16KiB",
        "iodepth": "16",
        "direct": "1",
        "numjobs": "1"
      },
      "read": {
        "rw": "read",
        "time_based": "1",
        "runtime": "120",
        "ramp_time": "0"
      }
    }
  }
```  

### Explaining Workload Include Files

There is an enormous amount of data that is collected via Openshift Prometheus, some of which is not relevant to all 
workloads, or not necessary for performance benchmarking. This lead us to the creation of include files, a file that
contains workload specific queries. These files can be located in *<root_dir>/snafu/utils/prometheus_labels*.

below is an example of the structure of the include file:

```
{
  "data": {
    "Average_Disk_IOPS_Read": {
        "label": "node_disk_reads_completed_total",
        "query": "(irate(node_disk_reads_completed_total{device!~\"dm.*\",device!~\"rb.*\",device!~\"nbd.*\"}[1m]))"
    },
    "Average_Disk_IOPS_Write": {
        "label": "node_disk_writes_completed_total",
        "query": "(irate(node_disk_writes_completed_total{device!~\"dm.*\",device!~\"rb.*\",device!~\"nbd.*\"}[1m]))"
    },
    "Average_Disk_Throughput_Read": {
        "label": "node_disk_read_bytes_total",
        "query": "(irate(node_disk_read_bytes_total{device!~\"dm.*\",device!~\"rb.*\",device!~\"nbd.*\"}[1m]))"
    },
    "Average_Disk_Throughput_Write": {
        "label": "node_disk_written_bytes_total",
        "query": "(irate(node_disk_written_bytes_total{device!~\"dm.*\",device!~\"rb.*\",device!~\"nbd.*\"}[1m]))"
    },
    ...
```

For each query we must include an object with a human readable tag, comma separated list of included labels, and the 
PromQL query.

By default all workloads will use the *<root_dir>/snafu/utils/prometheus_labels/included_labels.json* file for collections. 
If a workload needs targeted or more broad collection, contributers can upload a tools specific included file, i.e. 
 **<tool_name>_included_labels.json**.  


### Adding Prometheus collection trigger

In an attempt to simplify and gather only the relevant data to a specific test, the Prometheus collection trigger should 
be added to the end of wherever the workload executes a single sample. This will ensure that no data is captured outside 
of testing time or in between samples where data collection or other task are occurring.  

As discussed in previous sections there is a need to include context to the prometheus data, when extending this functionality 
contributers must create a dictionary containing sample specific information, most of which is already available to existing workloads. 

The following are the necessary parameters to include: 

* uuid - universally unique identifier, automatically created by benchmark-operator
* user - gathered from parameters passed from the CR file
* clustername - gathered from parameters passed from the CR file
* startime - sample start time in seconds, should be captured right before the test is started - used for bounding search query
* endtime - sample stop time in seconds, should be captured immediately after the test as finished - used for bounding search query
* sample - indication of sample number, used for statistical analysis of results and filtering
* tool - used to identify which include file to load, if applicable
* test_config - a dictionary containing the current sample's test parameters, used for statistical analysis of results and filtering.

below is an example of what should be add to your workload when extending this feature. 

```
trigger_workload.py

    emit_actions()
        ...
        **sample_starttime** = datetime.utcnow().strftime('%s')
        Run Test
        **sample_endtime** = datetime.utcnow().strftime('%s')
        
        Index benchmark data
        ...
        
    
        # trigger collection of prom data
        **sample_info_dict** = {"uuid": self.uuid,
                            "user": self.user,
                            "cluster_name": self.cluster_name,
                            "starttime": sample_starttime,
                            "endtime": sample_endtime,
                            "sample": self.sample,
                            "tool": "tool_name",
                            "test_config": self.tool_test_parameters_dict
                            }
    
        **yield sample_info_dict, "get_prometheus_trigger"**
```





