# Kafka

[Apache Kafka](https://kafka.apache.org/) is a distributed streaming platform

## Prerequisites
The [Operator Lifecycle Manager (OLM)](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Documentation/install/install.md) is required to run the Strimzi operator from [operatorhub.io](https://operatorhub.io). If your distribution of OpenShif/Kubernetes does not include this, you will need to install it first.

*Note: As of this writing, deploying the OLM from the deployment directory documented in the link above may lead to the Strimzi operator failing to launch. You may need to deploy instead from the `upstream/quickstart/olm.yaml` file as in:*

```bash
$ kubectl create -f https://raw.githubusercontent.com/operator-framework/operator-lifecycle-manager/master/deploy/upstream/quickstart/olm.yaml
```

## Running the Kafka infra

Given that you followed instructions to deploy the benchmark operator,
you can modify the [ripsaw_v1alpha1_kafka_cr.yaml](../resources/crds/ripsaw_v1alpha1_kafka_cr.yaml)

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: kafka-benchmark
  namespace: ripsaw
spec:
  cleanup: false
  workload:
    # To disable kafka set the servers.size to 0
    # Minimum valid servers.size is 3
    name: "kafka"
    args:
      servers:
        size: 3
      # By default we do not test persistent storage
      # If you set use_persistent_storage: True then you will also need to provide it
      # a valid class_name and volume_size
      storage:
        use_persistent_storage: False
        # class_name: "rook-ceph-block"
        # volume_size: 10Gi
      # Zookeeper defaults to 3 replicas. To change this modify zookeeper_replicas
      # zookeeper_replicas: 3
```

If you set `use_persistent_storage` to `true`, then you will need to provide a valid
StorageClass name for `class_name` and a valid volume size for `volume_size`.

Setting up a StorageClass is outside the scope of this documentation.


Once you are finished creating/editing the custom resource file, you can run it by:

```bash
$ kubectl create -f /path/to/ripsaw_v1alpha1_kafka_cr.yaml.yaml
```

Deploying the above will first result in the OLM catalogs to spawn.

```bash
NAME                                        READY     STATUS    RESTARTS   AGE
operatorhubio-catalog-7wj22                 1/1     Running   0          81s
operatorhubio-catalog-rgbg5                 1/1     Running   0          81s
```

This will then result in the Strimzi operator running.

```bash
$ kubectl -n ripsaw get pods -l name=strimzi-cluster-operator
NAME                                        READY     STATUS    RESTARTS   AGE
strimzi-cluster-operator-7b6677f9f9-qdn48   1/1       Running   0          1h
```

Once the Strimzi operator is running, the benchmark operator will then launch the Kafka
server infrastructure in a stateful manner.

```bash
$ kubectl -n ripsaw get pods -l strimzi.io/kind=Kafka
NAME                                              READY     STATUS              RESTARTS   AGE
kafka-benchmark-entity-operator-ddc84cd4f-vs7qt   0/3       ContainerCreating   0          6s
kafka-benchmark-kafka-0                           2/2       Running             0          1h
kafka-benchmark-kafka-1                           2/2       Running             0          1h
kafka-benchmark-kafka-2                           2/2       Running             0          1h
kafka-benchmark-zookeeper-0                       2/2       Running             0          1h
kafka-benchmark-zookeeper-1                       2/2       Running             0          1h
kafka-benchmark-zookeeper-2                       2/2       Running             0          1h
```

Note that the Kafka role is only an infrastructure role, and no workloads will be triggered directly
by running the CR as described here. You will need to separately define a workload in the CR.
