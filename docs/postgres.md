# PostgreSQL

[PostgreSQL](https://www.postgresql.org/) is an open source object-relational database system.

## Prerequisites
### OLM
The [Operator Lifecycle Manager (OLM)](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Documentation/install/install.md) is required to run the Zalando PostgreSQL operator from [operatorhub.io](https://operatorhub.io). If your distribution of OpenShift/Kubernetes does not include this, you will need to install it first.

```bash
$ kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-lifecycle-manager/master/deploy/upstream/quickstart/crds.yaml
$ kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-lifecycle-manager/master/deploy/upstream/quickstart/olm.yaml
```

## Using the Postgres Infra

### Customizing your CR

An example to enable only the Postgres infra (this does _not_ run a workload):

```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: postgres-infra
  namespace: ripsaw
spec:
  infrastructure:
    name: postgres
    args:
      servers:
        # Typical deployment size is 3
        size: 1
      storage:
        use_persistent_storage: True
        class_name: "rook-ceph-block"
        volume_size: 1Gi # A volume_size is required whether or not use_persistent_storage is True
      deployment:
        # These are deployment defaults from roles/postgres-infra/defaults
        # that can be overridden here.
        #
        ## For Generic K8s w/ Upstream OLM
        #postgres_operator_package: "postgres-operator"
        #olm_catalog: operatorhubio-catalog
        #olm_namespace: olm
        #
        ## For OpenShift v4 w/ Built-In OLM
        #postgres_operator_package: "postgres-operator"
        #olm_catalog: operatorhubio-catalog
        #olm_namespace: openshift-operator-lifecycle-manager

```

**Please see the example [CR file](../resources/crds/ripsaw_v1alpha1_postgres_cr.yaml) for further examples for different deployment environments.**

### Persistent Storage
If you set `spec.infrastructure.args.stroage.use_persistent_storage` to `true`, then you will need to provide a valid
StorageClass name for `spec.infrastructure.args.storage.class_name`

A valid volume size for `spec.infrastructure.args.storage.volume_size` is required whether or not you enable persistent storage.

*Setting up a StorageClass is outside the scope of this documentation.*

### Starting the Infra
Once you are finished creating/editing the custom resource file and the Ripsaw benchmark operator is running, you can start the infra with:

```bash
$ kubectl apply -f /path/to/cr.yaml
```

Deploying the above will first result in the postgres operator running.

```bash
$ kubectl get pods -l name=postgres-operator
NAME                                  READY     STATUS    RESTARTS   AGE
postgres-operator-7b489f685c-j6vs8   1/1       Running   0          4m59s
```

Once the postgres operator is running, the benchmark operator will then launch the postgres
server infrastructure in a stateful manner.

```bash
$ kubectl get pods -l spilo-role=master
NAME                                  READY     STATUS    RESTARTS   AGE
ripsaw-postgres-cluster-0             1/1       Running   0          9m58s
```

**Note that the postgres role is only an infrastructure role, and no workloads will be triggered directly
by running the CR as described here. You will need to separately define a workload in the CR (such as [pgbench](TODO)).**

## Cleanup
Currently, the postgres-operator deployment does not fully clean up on it's on when the
CR is deleted or changed to disable postgres. You will need to do this manually with:

```bash
$ kubectl delete csv postgres-operator.<version>
```
