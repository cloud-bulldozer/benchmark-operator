# Bring your own workload (byowl)

Bring your own workload enables users to pass their own prepared
container image with a set of commands.

## Running byowl

Build your CR

```yaml
apiVersion: benchmark.example.com/v1alpha1
kind: Benchmark
metadata:
  name: byowl-benchmark
spec:
  byowl:
    image: "quay.io/jtaleric/uperf:testing"
    clients: 1
    commands: |
      echo "This is my test workload";
      echo "This is my test workload again..."
```

This will launch the uperf container, and simply print the messages
above into the log of the container.

