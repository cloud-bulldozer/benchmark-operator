# Vegeta

[Vegeta](https://github.com/tsenart/vegeta) is a versatile HTTP load testing tool.

## Running Vegeta

Given that you followed instructions to deploy operator,
you can modify Vegeta's [cr.yaml](../resources/crds/ripsaw_v1alpha1_vegeta_cr.yaml) to make it fit with your requirements.

The option **runtime_class** can be set to specify an optional
runtime_class to the podSpec runtimeClassName.  This is primarily
intended for Kata containers.

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: vegeta-benchmark
  namespace: ripsaw-system
spec:
  elasticsearch:
    url: "http://esinstance.com:9200"
    index_name: ripsaw-vegeta
  workload:
    name: vegeta
    args:
      clients: 2
      image: quay.io/cloud-bulldozer/vegeta:latest
      hostnetwork: false
      targets:
        - name: 100w-ka
          urls:
            - GET https://mydomain.com/test.png
            - GET http://myunsecuredomain.com
          samples: 2
          workers: 100
          duration: 10
          keepalive: true
        - name: 20w
          urls:
            - GET https://domain.com/api/endpoint
          workers: 20
          duration: 10
```

It accepts the following parameters:

| Parameter    | Description                                                   | Optional | Default                               |
|--------------|---------------------------------------------------------------|----------|---------------------------------------|
| clients      | Number of vegeta clients to launch                            | yes      | 1                                     |
| image        | Overwrites vegeta image                                       | yes      | quay.io/cloud-bulldozer/vegeta:latest |
| hostnetwork  | Will launch vegeta clients in the same host network namespace | yes      | false                                 |
| nodeselector | Allow to specify a k8s nodeSelector for the clients           | yes      | -                                     |
  

The `targets` parameter contains the list of tests the vegeta pods will perform. Each of the test elements may have the following parameters:

| Option    | Description                                                                                           | Optional | Default |
|-----------|-------------------------------------------------------------------------------------------------------|----------|---------|
| name      | Test name                                                                                             | no       | -       |
| urls      | List of URLs. Specified using the [vegeta http format](https://github.com/tsenart/vegeta#http-format) | no       | -       |
| samples   | Number of iterations to execute                                                                       | yes      | 1       |
| workers   | Number of vegeta workers                                                                              | yes      | 1       |
| duration  | Test duration in seconds                                                                              | no       | -       |
| keepalive | Specifies whether to reuse TCP connections between HTTP requests                                      | yes      | false   |


## Vegeta benchmark behaviour

Tests described under the `targets` section are executed in series. In case of running multiple clients, each vegeta pod run their tests in parallel with the others.
This test synchronization is achieved using the redis message bus running in the benchmark operator pod.
Vegeta jobs make usage of pod anti-affinity rules to to deploy vegeta clients on different nodes:

```yaml
    affinity:                      
      podAntiAffinity:                                                  
        preferredDuringSchedulingIgnoredDuringExecution:                          
          - weight: 100                              
            podAffinityTerm:                                        
              labelSelector:                                        
                matchExpressions:                                        
                - key: app                                 
                  operator: In                              
                  values:                                        
                  - vegeta-benchmark-{{ trunc_uuid }}
```


## Storing results into Elasticsearch

The following metrics are indexed at one second intervals:

- rps: Rate of sent requests per second..
- throughput: Rate of successful requests per second.
- status_codes: Breakdown of the number status codes observed over the interval.
- requests: Total number of requests executed until that moment.
- p99_latency: 99th percentile of the request latency observed over the interval in µs.
- p97_latency: 95th percentile of the request latency observed over the interval in µs.
- req_latency: Average latency of all requests observed over the interval in µs.
- max_latency: Maximum latency observed during the Benchmark.
- min_latency: Minimum latency observed during the Benchmark.
- bytes_in: Incoming byte metrics over the interval.
- bytes_out: Outgoing byte metrics over the interval.
- targets: Targets file used.
- iteration: Iteration number.
- workers: Number of workers.
- hostname: Hostname from the host where the test is launched.
- keepalive: Whether keepalive is used or not.

### Dashboard example

Using the ElasticSearch metrics described above, we can build dashboards like the below.

![Vegeta dashboard](https://i.imgur.com/YWophlP.png)

The previous dashboard is available at [arsenal](https://github.com/cloud-bulldozer/arsenal/)

