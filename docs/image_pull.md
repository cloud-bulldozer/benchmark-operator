# Image Pull

## What does it do?

The Image Pull workload will take a list of images that exist in a container repository (e.x. Quay)
and copy them to the containers local working directory via [skopeo](https://github.com/containers/skopeo).
It will then display and/or index relevant data regarding the amount of time it took as well as any retries
or failures that occurred.

Additioanlly, it can be configured to run multiple pods at the same time, each reporting its own relevant data.
This allows the user to test concurrency of image pulls on a container image.

## Variables

### Required variables:

`image_list` a list of images in the format [image_transport]://[image_location]

### Optional variables:

`pod_count` total number of concurrent pods/tests to run (default: 1)

`timeout` how long, in seconds, to wait for the image to copy (default: 600)

`retries` how many times to retry failed copies (default: 0)

### Example CR

Your resource file may look like this when running 10 concurrent pods with 1 retry:

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: image-pull
  namespace: benchmark-operator
spec:
  elasticsearch:
    url: "http://es-instance.com:9200"
    index_name: "image-pull"
  workload:
    name: image_pull
    args:
      pod_count: 2
      timeout: 600
      retries: 1
      image_list:
        - docker://quay.io/cloud-bulldozer/backpack
        - docker://quay.io/cloud-bulldozer/fio
```
