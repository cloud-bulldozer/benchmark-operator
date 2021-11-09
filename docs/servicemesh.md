# Service Mesh

This is an automated benchmark of basic [Red Hat Openshift Service Mesh](https://www.redhat.com/en/about/press-releases/red-hat-launches-openshift-service-mesh-accelerate-adoption-microservices-and-cloud-native-applications) setup. The test uses [Hyperfoil](https://hyperfoil.io) to drive load through the mesh into several dummy workload instances, implemented using [Quarkus](https://quarkus.io/) application [Mannequin](https://github.com/RedHatPerf/mannequin).

The benchmark creates two namespaces: one for the Service Mesh [Control Plane](https://istio.io/docs/ops/deployment/architecture/), the other for the workload applications. Hyperfoil driver and the pod used to gather results is installed in the same namespace where Ripsaw is installed. When the benchmark completes those namespaces are destroyed along with other resources in Ripsaw namespace; you can inspect the results in JSON format in the benchmark job's pod output.

## Prerequisites

As this benchmark requires the operator to create new namespaces, you have to grant it an extra permission:

```bash
oc apply -f resources/self_provisioner_binding.yaml
```

Service Mesh and Hyperfoil operators must be [already installed](https://docs.openshift.com/container-platform/4.4/operators/olm-adding-operators-to-cluster.html) to the cluster before the benchmark starts.

## Optional setting

The option **runtime_class** can be set to specify an optional
runtime_class to the podSpec runtimeClassName.  This is primarily
intended for Kata containers.

The option **annotations** can be set to apply the specified
annotations to the pod metadata.

## Running the benchmark

Here is an example of the [benchmark CR](../config/samples/servicemesh/cr.yaml):

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: example
  namespace: benchmark-operator
spec:
  workload:
    name: servicemesh
    args:
      # Number of deployments with workload
      deployments: 3
      # Number of replicas in each deployment
      pods_per_deployment: 1
      # CPU resources request & limit for each workload pod
      workload_cpu: 4
      # List of nodes where the Hyperfoil (load-driver) will be deployed
      hyperfoil_agents:
      - node1
      - node2
      # Number of threads each agent should use
      hyperfoil_threads: 8
      # Name of the test. Currently supported are 'openmodel' and 'closedmodel'
      test_name: closedmodel
      # Settings for the closedmodel test: constant concurrency, variable throughput
      closedmodel:
        # Number of HTTP connections to keep (total across agents)
        shared_connections: 300
        # Concurrency factor
        users: 1050
        # Duration of warm-up phase
        warmup_duration: 10s
        # Duration of steady-state phase
        steadystate_duration: 10s
        # Distribution of the different request types
        weight_simple: 10
        weight_db: 10
        weight_proxy: 1
```

An alternative would be the openmodel test:

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: servicemesh-benchmark
  namespace: benchmark-operator
spec:
  workload:
    name: servicemesh
    args:
      # Name of the test. Currently supported are 'openmodel' and 'closedmodel'
      test_name: openmodel
      # Settings for the openmodel test: fixed throughput (increasing each iteration)
      # variable concurrency
      openmodel:
        # Number of HTTP connections to keep (total across agents)
        shared_connections: 2000
        # Throughput in the first steady-state (requests per second)
        initial_users_per_sec: 4200
        # Throughput increment
        increment_users_per_sec: 1050
        # Duration of the initial warm-up phase
        initial_rampup_duration: 60s
        # Duration of each steady-state phase
        steadystate_duration: 60s
        # Duration of each phase ramping the load up in between steady-states
        rampup_duration: 20s
        # Maximum number of iterations: maximum tested load would be
        #   initial_users_per_sec + increment_users_per_sec * max_iterations
        max_iterations: 50
        # Upper limit on the concurrency
        max_sessions: 90000
        # Distribution of the different request types
        weight_simple: 10
        weight_db: 10
        weight_proxy: 1
```


You can run it by:

```bash
oc apply -f config/samples/servicemesh/cr.yaml # if edited the original one
```

## Visualize the report

While the output from benchmark is a JSON, you can easily display

```bash
NAME=servicemesh-benchmark-xxxxxxx
oc logs -n benchmark-operator $NAME > /tmp/$NAME.json
cat /tmp/$NAME.json | docker run -i --rm quay.io/hyperfoil/hyperfoil-report /opt/report.sh > /tmp/$NAME.html
```

## Cleanup

When you're done simply delete the benchmark CR; the job and its pod will be garbage-collected automatically.
