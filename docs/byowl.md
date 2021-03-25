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


### NodeSelector, Taint/Tolerations, and RuntimeClass

You can add a node selector, taints/tolerations, and/or runtimeclass to the resulting Kubernetes resources like so:

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
	  runtimeclassname: "MyRuntimeClass"

```

This will launch the uperf container, and simply print the messages
above into the log of the container.

### A generic support:
You can add any section under `specoptions` and `containeroptions` in `byowl` CRD, which will go under POD's `spec` and `containers` respectively as below:


![BYOWL_DOC](https://user-images.githubusercontent.com/4022122/112431010-f31de200-8d64-11eb-9179-e6ae7eb0e2cd.png)


