# API Load

## What does it do?

The API Load workload will execute a load test using [OCM API Load](https://github.com/cloud-bulldozer/ocm-api-load)
After running it will perform an ES indexing for all the requests that have been generated and upload all the files to a snappy server.

## Sections

### Required sections

`elasticsearch` section, it is needed to index all the documents that are used for results.

### Optional sections

[`snappy`](https://github.com/cloud-bulldozer/snappy-data-server) section, it is needed to upload the raw files in case we need them for further analysis.

## Variables

### Required variables

`test_list` a list of the test that are goping to be run

`gateway_url` url for openshift API

`ocm_token` authorization token for API

`duration` default duration of each the attack

`rate` default rate of each attack

`aws_access_key` access key for AWS auhtentication

`aws_access_secret` access secret for AWS auhtentication

`aws_account_id` 12 digit account number for AWS auhtentication

### Optional variables

`cooldown` time in seconds, wait <cooldown> before the next attack occurs, default 60 seconds

`output_path` path were to write the results, default `/tmp/results`

`override` used to run a specific sub-command of `ocm-api-load`, like `version` or `help`

`sleep` time in seconds, checks redis status each <sleep> seconds, default 360 seconds

Each test can be provided with it's own configurations

`duration` default duration of each the attack

`rate` default rate of each attack

### Example CR

Your resource file with test list and custom configuraiton for some attacks:

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: api-load
  namespace: benchmark-operator
spec:
  elasticsearch:
    url: http://elastic.search.server
    index_name: "api-load"
  snappy:
    url: http://snappy.files.server
    user: user
    password: password
  workload:
    name: api_load
    args:
      gateway_url: https://api.openshift.com
      ocm_token: realTokenHere
      duration: 1
      rate: 5/s
      output_path: /tmp/results
      aws_access_key: realKey
      aws_access_secret: realSecret
      aws_account_id: 12DigitAccountNumber
      cooldown: 10
      sleep: 300
      test_list:
          self-access-token:
            rate: "1/s"
            duration: 1
          list-subscriptions:
            duration: 1
          access-review:
            rate: "7/s"
          register-new-cluster:
          register-existing-cluster:
          create-cluster:
          list-clusters:
          get-current-account:
          quota-cost:
          resource-review:
          cluster-authorizations:
          self-terms-review:
          certificates:

```
