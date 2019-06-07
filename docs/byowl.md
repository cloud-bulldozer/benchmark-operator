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

NOTE: Re-applying CR will not rerun the workload, so if you'd like to rerun a CR with same options because the environment
was updated, please add an empty variable to the CR. This will trigger a rerun
