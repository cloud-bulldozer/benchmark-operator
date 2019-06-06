# iperf3

[iperf3](https://iperf.fr/) is a network performance tool

## Running iperf

Given that you followed instructions to deploy operator,
you can modify [cr.yaml](../resources/crds/ripsaw_v1alpha1_iperf3_cr.yaml)


```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: iperf3-benchmark
  namespace: ripsaw
spec:
  name: iperf3
  args:
    pairs: 1
    hostnetwork: false
    pin: true
    pin_server: "master-0"
    pin_client: "master-1"
    port: 5201
    transmit_type: time
    transmit_value: 60
    omit_start: 0
    length_buffer: 128K
    window_size: 64k
    ip_tos: 0
    mss: 900
    streams: 1
    extra_options_client: ' '
    extra_options_server: ' '
    #retries: 200
```
Optional argument:
`retries` is an optional argument that can be used if you are running long tests
and don't want the logic to exit early, this is due to iperf logic using ansible's
retries to wait for iperf client job to be finish running. Note that the delay is
fixed to 15 seconds, and number of retries is defaulted to 10, i.e. a max of 150 seconds
for iperf client job to finish running. You can overwrite the number of retries by specifying
an integer value.

So for example: if you estimate a job to not take more than 900s,
then you'd probably give a `retries` of 60, as 60*15 is 900s.

The rest of the args are compulsory arguments that need to be passed and can cause
issues if missed, they are:

`pin` will allow the benchmark runner place nodes on specific nodes, using the `hostname` label.

`pin_server` what node to pin the server pod to.

`pin_client` what node to pin the client pod to.

`port` here is the port on which server listens on and client accesses it

`transmit_type` can take one of the three values `[time,bytes,blockcount]`

`transmit_value` needs to be set accordingly. For ex:

`transmit_type: time` then `transmit_value: 60` => it'll run for 60 seconds

`transmit_type: bytes` then `transmit_value: 4M` => it'll run until 4Mbytes have been transferred
and so on.

`omit_start` takes the first n seconds of the test, to skip past the TCP slow-start period

`length_buffer` points to length of buffer to read or write

`window_size` window size in bytes

`ip_tos` set the IP type of service, takes octal or hex values too so 0x34, 064 and 52 all point to same

`mss` set TCP maximum segment size

`streams` number of parallel client streams to run

`extra_options_client` is a string that holds extra iperf options that is passed along to iperf on the client,
so if you want to run udp it can be `-u` or if you'd like to run with
zero copy, in reverse direction and use repeating pattern in payload then it'd look like
`--repeating-payload --zerocopy`.

`extra_options_server` is similar to `extra_options_client` except its passed to the pod
that runs iperf server.

Please check man page on what arguments you can pass to client or server to use with
extra_options.

The sizes are usually followed KMGT for kilo/mega/giga/tera

Note: You can also store results on a pv, to do so add the following to spec in cr:

`hostnetwork` will test the performance of the node the pod will run on.

*Note:* If you want to run with hostnetwork on `OpenShift`, you will need to execute the following:

```bash

$ oc adm policy add-scc-to-user privileged -z benchmark-operator

```

```
  store_results: true
  results:
    path: /opt/result-data/
```

Once done creating/editing the resource file, you can run it by:

```bash
# kubectl apply -f resources/crds/benchmark_v1alpha1_iperf3_cr.yaml # if edited the original one
# kubectl apply -f <path_to_file> # if created a new cr file
```

Deploying the above(assuming pairs is set to 1) would result in

```bash
# kubectl get -o wide pods
NAME                                               READY   STATUS      RESTARTS   AGE     IP            NODE       NOMINATED NODE   READINESS GATES
benchmark-operator-75dd8678b9-km5k6                2/2     Running     0          3h49m   172.17.0.8    minikube   <none>           <none>
example-benchmark-iperf3-client-172.17.0.9-sd9sb   0/1     Completed   0          3h48m   172.17.0.12   minikube   <none>           <none>
example-benchmark-iperf3-server-0                  1/1     Running     0          3h49m   172.17.0.9    minikube   <none>           <none>
```

The `example-benchmark-iperf3-server-0` pod is where iperf server is running
The `example-benchmark-iperf3-client-172.17.0.9-sd9sb` is where the iperf client is running,
and if you notice the IP address in the name is same as the IP of server pod.

To review the results, `kubectl logs <client>`, it should look something similar:

```
[root@smicro-6029p-04 ~]# kubectl logs -f example-benchmark-iperf3-client-172.17.0.9-sd9sb                                                                                                                         
Connecting to host 172.17.0.9, port 5201                                                                                                                                                                           
[  4] local 172.17.0.12 port 54638 connected to 172.17.0.9 port 5201                                                                                                                                               
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd                                                                                                                                                   
[  4]   0.00-1.00   sec  1.43 GBytes  12.3 Gbits/sec    0    137 KBytes                                                                                                                                            
[  4]   1.00-2.00   sec  1.51 GBytes  13.0 Gbits/sec    0    137 KBytes                                                                                                                                            
[  4]   2.00-3.00   sec  2.30 GBytes  19.8 Gbits/sec    0    137 KBytes                                                                                                                                            
[  4]   3.00-4.00   sec  1.98 GBytes  17.0 Gbits/sec   20   95.4 KBytes                                                                                                                                            
[  4]   4.00-5.00   sec  1.51 GBytes  13.0 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]   5.00-6.00   sec  1.70 GBytes  14.6 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]   6.00-7.00   sec  1.52 GBytes  13.0 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]   7.00-8.00   sec  1.58 GBytes  13.6 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]   8.00-9.00   sec  1.59 GBytes  13.6 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]   9.00-10.00  sec  1.73 GBytes  14.9 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]  10.00-11.00  sec  1.90 GBytes  16.3 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]  11.00-12.00  sec  1.45 GBytes  12.5 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]  12.00-13.00  sec  1.90 GBytes  16.4 Gbits/sec    1   95.4 KBytes                                                                                                                                            
[  4]  13.00-14.00  sec  2.05 GBytes  17.6 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]  14.00-15.00  sec  1.49 GBytes  12.8 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]  15.00-16.00  sec  1.99 GBytes  17.1 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]  16.00-17.00  sec  1.60 GBytes  13.8 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]  17.00-18.00  sec  1.70 GBytes  14.6 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]  18.00-19.00  sec  1.62 GBytes  13.9 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]  19.00-20.00  sec  1.64 GBytes  14.1 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]  20.00-21.00  sec  1.80 GBytes  15.5 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]  21.00-22.00  sec  1.59 GBytes  13.6 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]  22.00-23.00  sec  1.47 GBytes  12.7 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]  23.00-24.00  sec  2.02 GBytes  17.4 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]  24.00-25.00  sec  1.64 GBytes  14.1 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]  25.00-26.00  sec  1.56 GBytes  13.4 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]  26.00-27.00  sec  1.56 GBytes  13.4 Gbits/sec    0   95.4 KBytes                                                                                                                                            
[  4]  27.00-28.00  sec  1.65 GBytes  14.1 Gbits/sec    0   95.4 KBytes
[  4]  28.00-29.00  sec  1.53 GBytes  13.2 Gbits/sec    0   95.4 KBytes
[  4]  29.00-30.00  sec  1.98 GBytes  17.0 Gbits/sec    0   95.4 KBytes
[  4]  30.00-31.00  sec  2.22 GBytes  19.1 Gbits/sec    0   95.4 KBytes
[  4]  31.00-32.00  sec  1.58 GBytes  13.6 Gbits/sec    0   95.4 KBytes
[  4]  32.00-33.00  sec  1.53 GBytes  13.1 Gbits/sec    0   95.4 KBytes
[  4]  33.00-34.00  sec  1.71 GBytes  14.7 Gbits/sec    0   95.4 KBytes
[  4]  34.00-35.00  sec  1.79 GBytes  15.4 Gbits/sec    0   95.4 KBytes
[  4]  35.00-36.00  sec  1.60 GBytes  13.8 Gbits/sec    0   95.4 KBytes
[  4]  36.00-37.00  sec  1.71 GBytes  14.7 Gbits/sec    0   95.4 KBytes
[  4]  37.00-38.00  sec  1.65 GBytes  14.2 Gbits/sec    0   95.4 KBytes
[  4]  37.00-38.00  sec  1.65 GBytes  14.2 Gbits/sec    0   95.4 KBytes
[  4]  38.00-39.00  sec  1.61 GBytes  13.8 Gbits/sec   36   95.4 KBytes
[  4]  39.00-40.00  sec  1.51 GBytes  13.0 Gbits/sec    0   95.4 KBytes
[  4]  40.00-41.00  sec  1.57 GBytes  13.5 Gbits/sec    0   95.4 KBytes
[  4]  41.00-42.00  sec  1.71 GBytes  14.7 Gbits/sec    0   95.4 KBytes
[  4]  42.00-43.00  sec  1.65 GBytes  14.1 Gbits/sec    0   95.4 KBytes
[  4]  43.00-44.00  sec  1.86 GBytes  16.0 Gbits/sec    0   95.4 KBytes
[  4]  44.00-45.00  sec  1.63 GBytes  14.0 Gbits/sec    0   95.4 KBytes
[  4]  45.00-46.00  sec  2.47 GBytes  21.2 Gbits/sec    0   95.4 KBytes
[  4]  46.00-47.00  sec  1.49 GBytes  12.8 Gbits/sec    0   95.4 KBytes
[  4]  47.00-48.00  sec  1.60 GBytes  13.7 Gbits/sec    0   95.4 KBytes
[  4]  48.00-49.00  sec  1.57 GBytes  13.5 Gbits/sec    0   95.4 KBytes
[  4]  49.00-50.00  sec  1.53 GBytes  13.1 Gbits/sec    0   95.4 KBytes
[  4]  50.00-51.00  sec  1.62 GBytes  13.9 Gbits/sec    0   95.4 KBytes
[  4]  51.00-52.00  sec  1.59 GBytes  13.6 Gbits/sec    0   95.4 KBytes
[  4]  52.00-53.00  sec  1.78 GBytes  15.3 Gbits/sec    1   95.4 KBytes
[  4]  53.00-54.00  sec  1.77 GBytes  15.2 Gbits/sec    1   95.4 KBytes
[  4]  54.00-55.00  sec  1.44 GBytes  12.4 Gbits/sec    0   95.4 KBytes
[  4]  55.00-56.00  sec  1.49 GBytes  12.8 Gbits/sec    0   95.4 KBytes
[  4]  56.00-57.00  sec  1.56 GBytes  13.4 Gbits/sec    0   95.4 KBytes
[  4]  57.00-58.00  sec  1.63 GBytes  14.0 Gbits/sec    0   95.4 KBytes
[  4]  58.00-59.00  sec  1.68 GBytes  14.4 Gbits/sec    0   95.4 KBytes
[  4]  59.00-60.00  sec  1.66 GBytes  14.3 Gbits/sec    0   95.4 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-60.00  sec   101 GBytes  14.5 Gbits/sec   59             sender
[  4]   0.00-60.00  sec   101 GBytes  14.5 Gbits/sec                  receiver

iperf Done.
```

As you can see it shows how much data was transferred in each second interval as well as
bandwidth and then the summary.
