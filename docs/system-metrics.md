# System-metrics collection

Benchmark-operator is able to collect prometheus metrics from the cluster at the end of a benchmark. To do so, it creates a k8s job that uses [kube-burner](https://github.com/cloud-bulldozer/kube-burner) to collect the Prometheus metrics given by a configuration file. This system metrics collection mechanism in available for all workloads except `kube-burner` and `backpack`.

This feature is disabled by default, it can be enabled by adding a `system_metrics` section to a benchmark CR.

```yaml
  system_metrics:
    collection: true (Defaults to false)
    prom_url: <Valid prometheus endpoint, by default https://prometheus-k8s.openshift-monitoring.svc.cluster.local:9091>
    index_name: <ES index name, defaults to system-metrics>
    es_url: <valid ES endpoint>
    prom_token: <valid prometheus token, in an OpenShift environment can be obtained with oc sa get-token -n openshift-monitoring prometheus-k8s>
    metrics_profile: <valid metric profile name or URL pointing to it, by default node-metrics.yml>
    step: <Prometheus step size, by default 30s>
    image: <Kube-burner image, by default quay.io/cloud-bulldozer/kube-burner:latest>
```

As stated in the example above, `metrics_profile` points to node-metrics.yml, (this file is available within the system-metrics role of this repo), however it can be configured pointing to an external URL like in the example below:

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: example-benchmark
  namespace: my-ripsaw
spec:
  system_metrics:
    enabled: true
    prom_token: eyJhbGciOiJSUzI1NiIsImtpZCI6IlljTUxlUHBTY2hvUVJQYUlZWmV5MTE4d3VnRFpjUUh5MWZtdE9hdnlvNFUifQ.eyJpc3MiOiJrdWJlcnopeVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJvcGVuc2hpZnQtbW9uaXRvcmluZyIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJwcm9tZXRoZXVzLWs4cy10b2tlbi12NGo3YyIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJwcm9tZXRoZXVzLWs4cyIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjFkYTdkMTRkLWE2MTktNDZjYS1iZGRlLTMzOTYxOWYxMmM4MiIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpvcGVuc2hpZnQtbW9uaXRvcmluZzpwcm9tZXRoZXVzLWs4cyJ9.PJp5pD_CjMG05vVLFdxUDRWGA8C71TNyRsUcHmpMlnZLQWBwxZSDZ-Uh3y6g1O-Yz3nopeCoZLB6lugxxalcT1DhiEC9yNK53Lr6HLqaz8nWUbRPbex0913KcuSsnpeRj7tzlwQ2K3WbtIeyyHpG5vAeff07LDvHUcPsc3B_dyetGnInClBHFVEJRES6f5DbIUidtXZEfYKANJNcssly0qZMZicwvM4a_pRp6ctGB-zzR6Ac4lh3b1JLfl_5TLGuuoYEOAeJPVUF4TjemsNNJ5BlycEkVI377LKNdHf83wua5pn3ItJtKE5gdrG833203p-y0pj-UDJj2bAv0cjUQ
    metrics_profile: https://raw.githubusercontent.com/cloud-bulldozer/benchmark-operator/master/roles/kube-burner/files/metrics-aggregated.yaml
  elasticsearch:
    url: https://search-perfscale-dev-chmf5l4sh66lvxbnadi4bznl3a.us-west-2.es.amazonaws.com:443
    index_name: ripsaw-uperf
  metadata:
    collection: false
  cleanup: false
  workload:
    name: uperf
    args:
      hostnetwork: false
      serviceip: false
      pin: false
      multus:
        enabled: false
      samples: 1
      pair: 1
      test_types:
        - stream
      protos:
        - tcp
      sizes:
        - 1024
      nthrs:
        - 1
      runtime: 120
```
