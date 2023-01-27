nighthawk-benchmark
=========

HTTP benchmark workload. More details [here](https://github.com/envoyproxy/nighthawk).

## Running Nighthawk

Here are some sample CRs and instructions to run this workload.

### Sample CR for testing
```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: nighthawk-benchmark
  namespace: benchmark-operator
spec:
  clustername: myk8scluster
  elasticsearch:
    url: https://search-perfscale-dev-chmf5l4sh66lvxbnadi4bznl3a.us-west-2.es.amazonaws.com:443
  workload:
    cleanup: true
    name: nighthawk
    args:
      url: https://www.testurlhere.com
      image: quay.io/vchalla/nighthawk:latest
      terminations: ["http", "edge", "passthrough", "reencrypt"]
      kind: pod
      hostnetwork: false
      number_of_routes: 3
      samples: 1
      concurrency: 8
      duration: 60
      connections: 80 
      max_requests_per_connection: 50
      debug: true
```
### Sample CR with default parameters
```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: nighthawk-benchmark
  namespace: benchmark-operator
spec:
  clustername: myk8scluster
  elasticsearch:
    url: https://search-perfscale-dev-chmf5l4sh66lvxbnadi4bznl3a.us-west-2.es.amazonaws.com:443
  workload:
    cleanup: true
    name: nighthawk
    args:
      terminations: ["http"]
```

### Parameters
`url` Target url to test. Works as a client server model with client-server pod pairs.  
`image`: Image if needed to be overriden from the default one.   
`terminations`: List of network terminations to be applied.  
`kind`: Kind of machine to run workload on. For now only pod is supported.  
`hostnetwork`: Will test the performance of the node the pod will run on.   
`number_of_routes`: Number of routes to be created.   
`samples`: Number of times to run the workload.  
`concurrency`:  The number of concurrent event loops that should be used. Specify 'auto' to "\
                "let Nighthawk leverage all vCPUs that have affinity to the Nighthawk process"\
                ". Note that increasing this results in an effective load multiplier combined"\
                " with the configured --rps and --connections values"   
`duration`: The number of seconds that the test should be running.  
`connections`: The maximum allowed number of concurrent connections per event loop.   
`max_requests_per_connection`: Max requests per connection.  
`debug`: To turn on debug logs.   

### Once the testing is done the results are published to elastic search as follows.
```yaml
"hits" : [
      {
        "_index" : "ripsaw-nighthawk-results",
        "_type" : "_doc",
        "_id" : "4a2a5aa5c41a3ec53bdc5de9f9ea4a04f12cc8fa967fa2033b95f82e2ae356f0",
        "_score" : 1.0,
        "_source" : {
          "concurrency" : 8,
          "duration" : 60,
          "connections" : 80,
          "max_requests_per_connection" : 4294937295,
          "rps" : 5,
          "kind" : "pod",
          "url" : "http://nighthawk-benchmark-route-http-2-benchmark-operator.apps.vchalla-perfscale.perfscale.devcluster.openshift.com",
          "workload" : "nighthawk",
          "uuid" : "e777d5e4-4b9e-5e90-a453-61e30caa9a5b",
          "user" : "ripsaw",
          "cluster_name" : "myk8scluster",
          "targets" : [
            "http://nighthawk-benchmark-route-http-2-benchmark-operator.apps.vchalla-perfscale.perfscale.devcluster.openshift.com"
          ],
          "hostname" : "nighthawk-client-10.0.221.20-nginx-http-2-e777d5e4-pmxvt",
          "requested_qps" : 40,
          "throughput" : 39.98936405750067,
          "status_codes_1xx" : 0,
          "status_codes_2xx" : 2400,
          "status_codes_3xx" : 0,
          "status_codes_4xx" : 0,
          "status_codes_5xx" : 0,
          "p50_latency" : 3.188863,
          "p75_latency" : 4.302335,
          "p80_latency" : 5.629951,
          "p90_latency" : 10.191871,
          "p95_latency" : 13.958143,
          "p99_latency" : 24.370175,
          "p99_9_latency" : 39.522303,
          "avg_latency" : 4.663531,
          "timestamp" : "2022-08-18T19:57:57.357909411Z",
          "bytes_in" : 1108800.0,
          "bytes_out" : 331200.0,
          "iteration" : 1,
          "run_id" : "NA"
        }
      }
    ]
```
### And also you can verify the logs in your openshift namespace using the below script
```
echo -n "`oc get all | grep -i -e 'completed' | cut -f 1 -d ' '`" > output.txt

cat output.txt | awk '{print $0}' | while
	read each
do
	echo "client name: $each"
	echo "client info"
	echo -n "`oc get $each -o yaml | grep -i -e "clientfor" -e 'port' -A 2`"
	echo -e "\n"
	echo "client logs"
	echo -n "`oc logs $each | tail -n 5`"
	echo -e "\n\n"
done
```