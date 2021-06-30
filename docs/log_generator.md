# Log Generator

## What does it do?

The Log Generator writes messages of a set size and at a set rate to stdout. If provided
it will also verify that all messages were recieved by the backend log aggregator.
This data will also be indexed if Elasticsearch information is provided.

*NOTE* This workload will not deploy the backend log aggregator

## Variables

### Required variables:

`size` the size, in bytes, of the message to send

`duration` how long, in minutes, messages should be sent for

`messages_per_second` the number of messages per second (mutually exclusive with messages_per_minute)

`messages_per_minute` the number of messages per minute (mutually exclusive with messages_per_second)

### Optional variables:

`pod_count` total number of log generator pods to launch (default: 1)

`timeout` how long, in seconds, after have been sent to allow the backend service to receive all the messages (default: 600)

`snafu_disable_logs` Disable all logging in the pod from the snafu logger, thereby only leaving the generated log messages on stdout (default: False)

### Verification variables:

To verify your messages have been received by the backend aggregator you must provide information for ONLY ONE of the supported
backends: Elasticsearch or AWS CloudWatch

Elasticsearch Backend:

`es_url` the elasticsearch url to query for results.

`es_index` the index to search for the sent messages (default: app*)

`es_token` the bearer token to use to access elasticsearch if required

AWS CloudWatch:

`cloudwatch_log_group` the aws cloudwatch log group to query

`aws_region` the region that cloudwatch is deployed to

`aws_access_key` the access key to use to query cloudwatch

`aws_secret_key` the secret key to use to query cloudwatch

Kafka:

`kafka_bootstrap_server` the connection details to kafka

`kafka_topic` the topic where logs are stored

`kafka_check` if you want to verify that log messages made it to kafka sink (requires a high timeout)

Your resource file may look like this when using an Elasticsearch Backend:

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: log-generator
  namespace: ripsaw-system
spec:
  elasticsearch:
    url: "http://es-instance.com:9200"
    index_name: log-generator
  workload:
    name: log_generator
    args:
      pod_count: 2
      size: 512
      messages_per_second: 10
      duration: 1
      es_url: "https://my-es-backend.com"
      es_token: "sha256~myToken"
      timeout: 600
      label:
        key: foo
        value: ""
```

Your resource file may look like this when using an AWS CloudWatch Backend:

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: log-generator
  namespace: ripsaw-system
spec:
  elasticsearch:
    url: "http://es-instance.com:9200"
    index_name: log-generator
  workload:
    name: log_generator
    args:
      pod_count: 10
      size: 1024
      messages_per_second: 100
      duration: 10
      cloudwatch_log_group: "my_log_group"
      aws_region: "us-west-2"
      aws_access_key: "myKey"
      aws_secret_token: "myToken"
      timeout: 800
      label:
        key: bar
        value: ""
```

Your resource file may look like this when using a Kafka Backend:

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: log-generator
  namespace: ripsaw-system
spec:
  elasticsearch:
    url: "http://es-instance.com:9200"
    index_name: log-generator
  workload:
    name: log_generator
    args:
      pod_count: 2
      size: 512
      messages_per_second: 10
      duration: 1
      kafka_bootstrap_server: "my-cluster-kafka-bootstrap.amq:9092"
      kafka_topic: "topic-logging-app"
      timeout: 600
      label:
        key: foo
        value: ""
```

