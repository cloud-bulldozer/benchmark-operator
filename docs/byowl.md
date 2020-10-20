# Bring your own workload (byowl)

Bring your own workload enables users to pass their own prepared
container image with a set of commands.

## Running byowl

Build your CR

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: byowl-benchmark
  namespace: my-ripsaw
spec:
  workload:
    name: byowl
    args:
      image: "quay.io/me/myawesomebenchmarkimage"
      clients: 1
      commands: "echo Test"
```


### NodeSelector and Taint/Tolerations

You can add a node selector and/or taints/tolerations to the resulting Kubernetes resources like so:

```yaml
spec:
  workload:
    name: byowl
    args:
      nodeselector:
        foo: bar
      tolerations:
      - key: "taint-to-tolerate"
        operator: "Exists"
        effect: "NoSchedule"

```

This will launch the uperf container, and simply print the messages
above into the log of the container.
