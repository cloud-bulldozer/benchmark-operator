# Bring your own workload (byowl)

Bring your own workload enables users to pass their own prepared
container image with a set of commands.

## Running byowl

Build your CR and appropriate for your workload. You will need to supply a path
to a repo image to run, and then a set of commands to execute on that image.

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
above into the log of the container. The pod will be retained in a _Completed_ state
once the workload run completes so that you may analyze the logs. Running a
`kubectl delete -f <your_cr_file>` will result in the container being removed.

