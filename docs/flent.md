# Flent

[Flent](https://flent.org/) is a network performance tool

## Running Flent

Given that you followed instructions to deploy operator,
you can modify [cr.yaml](../config/samples/flent/cr.yaml)

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: flent-benchmark
  namespace: benchmark-operator
spec:
  clustername: myk8scluster
  #elasticsearch:
  #   server: elk.server.com
  #   port: 9200
  #test_user: username_to_attach_to_metadata
  workload:
    # cleanup: true
    name: flent
    args:
      #image: quay.io/username/reponame:tagname
      hostnetwork: false
      multus:
        enabled: false
      pin: false
      pin_server: "node-0"
      pin_client: "node-1"
      pair: 1
      test_types:
        - tcp_download
      runtime: 30
```
`test_types` is a list of all tests it should run.

As of flent 1.3.2, the following tests are available:
```
  bursts                     :  Latency measurements under intermittent UDP bursts
  bursts_11e                 :  802.11e Latency measurements under intermittent UDP bursts
  cisco_5tcpup               :  RTT Fair Realtime Response Under Load
  cisco_5tcpup_2udpflood     :  Cisco 5TCP up + 2 6Mbit UDP
  cubic_bbr                  :  Cubic VS BBR smackdown
  cubic_cdg                  :  Cubic VS CDG smackdown
  cubic_dctcp                :  Cubic VS DCTCP smackdown
  cubic_ledbat               :  Cubic VS Ledbat smackdown
  cubic_ledbat_1             :  Cubic vs LEDBAT upload streams w/ping
  cubic_reno                 :  Cubic VS Reno smackdown
  cubic_westwood             :  Cubic VS Westwood
  dashtest                   :  DASH testing
  dslreports_8dn             :  8 down - dslreports dsl test equivalent
  http                       :  HTTP latency test
  http-1down                 :  HTTP get latency with competing TCP download stream
  http-1up                   :  HTTP get latency with competing TCP upload stream
  http-rrul                  :  HTTP get latency with competing RRUL test
  iterated_bidirectional     :  Iterated TCP bidirectional transfers example
  ledbat_cubic_1             :  Cubic vs LEDBAT upload streams w/ping
  ping                       :  Ping test (ICMP and UDP)
  qdisc-stats                :  Capture qdisc stats
  reno_cubic_westwood_cdg    :  Realtime Response Under Load
                                (with different congestion control algs)
  reno_cubic_westwood_ledbat :  Realtime Response Under Load
                                (with different congestion control algs)
  reno_cubic_westwood_lp     :  Realtime Response Under Load
                                (with different congestion control algs)
  rrul                       :  Realtime Response Under Load
  rrul46                     :  Realtime Response Under Load - Mixed IPv4/6
  rrul46compete              :  Realtime Response Under Load - Mixed v4/v6 compete
  rrul_100_up                :  100 up vs 1 down - exclusively Best Effort
  rrul_50_down               :  50 down vs 1 up - exclusively Best Effort
  rrul_50_up                 :  50 up vs 1 down - exclusively Best Effort
  rrul_be                    :  Realtime Response Under Load - exclusively Best Effort
  rrul_be_iperf              :  Realtime Response Under Load - exclusively Best Effort (Iperf TCP)
  rrul_be_nflows             :  Realtime Response Under Load - Best Effort, configurable no of flows
  rrul_cs8                   :  Realtime Response Under Load CS8, one flow per CS/precedence level
  rrul_icmp                  :  Realtime Response Under Load - Best Effort, only ICMP ping
  rrul_noclassification      :  Realtime Response Under Load - no classification on data flows
  rrul_prio                  :  Realtime Response Under Load - Test Prio Queue
  rrul_torrent               :  Torrent-like competition
  rrul_up                    :  Realtime Response Under Load - upload only
  rtt_fair                   :  RTT Fair Realtime Response Under Load
  rtt_fair4be                :  RTT Fair Realtime Response Under Load
  rtt_fair6be                :  RTT Fair Realtime Response Under Load
  rtt_fair_up                :  RTT Fair upstream only
  rtt_fair_var               :  RTT Fair - variable number of hosts
  rtt_fair_var_down          :  RTT Fair - variable number of hosts (download only)
  rtt_fair_var_mixed         :  RTT Fair - variable number of hosts (mixed up and down)
  rtt_fair_var_up            :  RTT Fair - variable number of hosts (upload only)
  sctp_vs_tcp                :  SCTP vs TCP
  tcp_12down                 :  TCP download - 12 streams w/ping
  tcp_12up                   :  TCP upload - 12 streams w/ping
  tcp_1down                  :  Single TCP download stream w/ping
  tcp_1up                    :  Single TCP upload stream w/ping
  tcp_1up_noping             :  Single TCP upload stream
  tcp_2down                  :  TCP download - 2 streams w/ping
  tcp_2up                    :  TCP upload - 2 streams w/ping
  tcp_2up_delay              :  Two TCP upload streams; 2nd stream started delayed
  tcp_2up_square             :  Two TCP upload streams; 2nd stream started delayed
  tcp_2up_square_westwood    :  Two TCP upload streams; 2nd stream started delayed
  tcp_4down                  :  TCP download - 4 streams w/ping
  tcp_4up                    :  TCP upload - 4 streams w/ping
  tcp_4up_squarewave         :  Four TCP upload streams; 2nd streams started delayed, cubic vs BBR
  tcp_50up                   :  TCP upload - 8 streams w/ping
  tcp_6down                  :  TCP download - 6 streams w/ping
  tcp_6up                    :  TCP upload - 6 streams w/ping
  tcp_8down                  :  TCP download - 8 streams w/ping
  tcp_8up                    :  TCP upload - 8 streams w/ping
  tcp_bidirectional          :  Bidirectional TCP streams w/ping
  tcp_download               :  TCP download stream w/ping
  tcp_ndown                  :  TCP download - N streams w/ping
  tcp_nup                    :  TCP upload - N streams w/ping
  tcp_upload                 :  TCP upload stream w/ping
  tcp_upload_1000            :  1000 up - exclusively Best Effort
  tcp_upload_prio            :  TCP upload stream w/ToS prio bits
  udp_flood                  :  UDP flood w/ping
  udp_flood_var_up           :  UDP flood w/ping - variable number of hosts
  udp_flood_var_up_stagger   :  UDP flood w/ping - variable number of hosts, staggered start
  voip                       :  VoIP one-way stream test
  voip-1up                   :  VoIP one-way stream test with competing TCP stream
  voip-rrul                  :  VoIP one-way stream test with competing RRUL test
```
Not every test works in benchmark-operator. Tests that require something other than netserver will not work. Tests that require additional arguments will also not work.
The voip tests do not work, and the cisco and burst tests do not work.

The tcp_*, udp_, and more should work. tcp_download was the most tested test.


`client_resources` and `server_resources` will create flent client's and server's containers with the given k8s compute resources respectively [k8s resources](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/)

`hostnetwork` will test the performance of the node the pod will run on.

*Note:* If you want to run with hostnetwork on `OpenShift`, you will need to execute the following:

```bash

$ oc adm policy add-scc-to-user privileged -z benchmark-operator

```

`image` The snafu image built for flent. Optional. Defaults to the cloud-bulldozer one.

`pin` will allow the benchmark runner place nodes on specific nodes, using the `hostname` label.

`pin_server` what node to pin the server pod to.

`pin_client` what node to pin the client pod to.

`multus[1]` Configure our pods to use multus.

[1] https://github.com/intel/multus-cni/tree/master/examples

```yaml
  hostnetwork: false
  multus:
    enabled: false
  pair: 2
  test_types:
    - tcp_download
  runtime: 30
```

Will run the flent test `tcp_download` on two pairs of server and clients for 30 seconds.
The output of tcp_download will include the summary plus the details of the downloads and pings.

If the user desires to test with Multus, use the below Multus `NetworkAtachmentDefinition`
as an example:

```
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-range-0
spec:
  config: '{
            "cniVersion": "0.3.1",
            "type": "macvlan",
            "master": "eno1",
            "mode": "bridge",
            "ipam": {
                    "type": "host-local",
                    "ranges": [
                    [ {
                       "subnet": "11.10.0.0/16",
                       "rangeStart": "11.10.1.20",
                       "rangeEnd": "11.10.3.50"
                    } ] ]
            }
        }'
---
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: macvlan-range-1
spec:
  config: '{
            "cniVersion": "0.3.1",
            "type": "macvlan",
            "master": "eno1",
            "mode": "bridge",
            "ipam": {
                    "type": "host-local",
                    "ranges": [
                    [ {
                       "subnet": "11.10.0.0/16",
                       "rangeStart": "11.10.1.60",
                       "rangeEnd": "11.10.3.90"
                    } ] ]
            }
        }'
```

This will use the same IP subnet across nodes, but not overlap
IP addresses.

To enable Multus in Ripsaw, here is the relevant config.

```
      ...
      multus:
        enabled: true
        client: "macvlan-range-0"
        server: "macvlan-range-1"
      pin: true
      pin_server: "openshift-master-0.dev4.kni.lab.eng.bos.redhat.com"
      pin_client: "openshift-master-1.dev4.kni.lab.eng.bos.redhat.com"
      ...

```

Once done creating/editing the resource file, you can run it by:

```bash
# kubectl apply -f config/samples/flent/cr.yaml # if edited the original one
# kubectl apply -f <path_to_file> # if created a new cr file
```

### Storing results into Elasticsearch

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: example-benchmark
  namespace: benchmark-operator
spec:
  clustername: myk8scluster
  test_user: test_user # user is a key that points to user triggering ripsaw, useful to search results in ES
  elasticsearch:
    server: <es_host>
    port: <es_port>
  workload:
    name: flent
    args:
      hostnetwork: false
      multus:
        enabled: false
      pin: false
      pin_server: "node-0"
      pin_client: "node-1"
      pair: 1
      test_types:
        - tcp_download
      runtime: 30
```

The new fields :

`elasticsearch.server` this is the elasticsearch cluster ip you want to send the result data to for long term storage.

`elasticsearch.port` port which elasticsearch is listening, typically `9200`.

`user` provide a user id to the metadata that will be sent to Elasticsearch, this makes finding the results easier.

By default we will utilize the `flent-results` index for Elasticsearch.

Deploying the above(assuming pairs is set to 1) would result in

```bash
# oc get pods -n benchmark-operator
NAME                                            READY   STATUS      RESTARTS   AGE
benchmark-operator-f84bdbd8f-n6cnc              3/3     Running     0          34m
flent-bench-client-10.116.0.54-533b6892-dc5cd   0/1     Completed   0          32m
```

The first pod is our Operator orchestrating the Flent workload.

To review the results, `oc logs <client>`, the top of the output is
the actual workload that was passed to flent (From the values in the custom resource).

Note: If cleanup is not set in the spec file then the client pods will be killed after
600 seconds from it's completion. The server pods will be cleaned up immediately
after client job completes

```
... Trimmed output ...
+-------------------------------------------------- flent Results --------------------------------------------------+
Run : 1
Flent options:

```yaml
  hostnetwork: false
  pair: 1
  test_types:
  - tcp_download
  runtime: 30
```

Flent results:
```
                           avg       median          # data pts
 Ping (ms) ICMP :         0.12         0.07 ms              350
 TCP download   :      6778.82      6704.92 Mbits/s         350
```
+-------------------------------------------------------------------------------------------------------------------+

