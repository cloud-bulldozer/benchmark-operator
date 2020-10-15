# Cerberus Integration

How To:
* [What is it](#what-is-it)
* [How it Works](#how-it-works)
* [How to enable Cerberus](#how-to-enable-Cerberus)

# What is it

What is Cerberus? [Cerberus](https://github.com/openshift-scale/cerberus) is a project that will watch an Openshift/Kubernernetes cluster
for dead nodes, component failures, etc and provide a healthly/unhealthy (True/False) signal. 

# How it Works

For installation and startup instructions for Cerberus please see [https://github.com/openshift-scale/cerberus](https://github.com/openshift-scale/cerberus)

Ripsaw has been enabled to check a provided Cerberus url for a True/False signal. True being healthy and False being unhealthy (meaning a component
has failed). If ripsaw encounters a False signal it will set the State of the benchmark to Error and the benchmark will not proceed
further. 

It will NOT stop any running components or kill any pods when a failure signal is found. That means that any pods that are running will
continue to run. Ripsaw will simply not proceed to any next steps of the workload. Everything is left in this state to aid in any
potential debugging that may need to be done.

Once an Error state is entered it will not go back to its previous state. This means that you will either need to restart the benchmark
entirely or manually change the state of the benchmark.

# How to enable Cerberus

Enabling Cerberus is very easy. Simply define the cerberus_url variable in your CR file with the url:port of the Cerberus service you wish
to use.

For example, if Cerberus is running at 1.2.3.4:8080

```
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: byowl-benchmark
  namespace: my-ripsaw
spec:
  elasticsearch:
    server: "http://foo.bar.com:9200"
  cerberus_url: "http://1.2.3.4:8080"
  workload:
    name: byowl
...
```

NOTE: The cerberus url MUST BE in the format http://[address]:[port]

Once Cerberus is enabled the connection status can be viewed by getting the benchmark status. If Cerberus is not
enabled the connection status will simply be "not connected"

```
$ kubectl -n my-ripsaw get benchmarks.ripsaw.cloudbulldozer.io
NAME              TYPE    STATE   METADATA STATE   CERBERUS    UUID                                   AGE
byowl-benchmark   byowl   Error   Complete         Connected   11faec65-4009-58e8-ac36-0233f0fc822d   10m
```
