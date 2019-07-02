## Installation
This guide uses minishift version v1.33.0+ as the local Kubernetes cluster
and quay.io for the public registry. We also test on minikube version v0.35+.
`kubectl` is used but can be substituted* with `oc`.

### Supported versions
* [OKD](https://www.okd.io/)
  * Experimental: 3.11
* [OpenShift® Container Platform](https://www.openshift.com/products/container-platform/)
  * Fully supported: 4.0
  * Experimental: 3.11
* [kubernetes](https://kubernetes.io/)
  * Experimental: 1.11-1.13

Note: Experimental tag refers to some workloads that might be functioning

### Requirements
<!---
TODO(aakarsh):
Get the specific versions for requirements
-->

The main requirements are as follows:
* Running Kubernetes cluster - [supported versions](#Supported-Versions)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [git](https://git-scm.com/downloads)

Note: Please login as admin user

The following requirements are needed to make/test changes to operator:
* [operator-sdk](https://github.com/operator-framework/operator-sdk)
* [docker](https://docs.docker.com/install/)

Note: You also require a [quay](https://quay.io/) account to push images

The following optional requirements are needed if using OKD/OCP < 4.0:
* [dep](https://golang.github.io/dep/docs/installation.html)
* [operator-sdk](https://github.com/operator-framework/operator-sdk)
* [go](https://golang.org/dl/)
* [OLM](https://github.com/operator-framework/operator-lifecycle-manager)

The workloads could also have their own requirements which would be specified
in the installation guide.

### Deploying operator
Note: The benchmark-operator's code-name is ripsaw, so the names have been
used interchangeably.

First we'll need to clone the operator:

```bash
# git clone https://github.com/cloud-bulldozer/ripsaw
# cd ripsaw
# export KUBECONFIG=<your_kube_config> # if not already done
```

We try to maintain all resources created/required by ripsaw in the namespace
ripsaw, so we'll create the namespace and add a context with admin user and
can be done as follows:

```bash
# kubectl apply -f resources/namespace.yaml
# kubectl config set-context ripsaw --namespace=ripsaw --cluster=<your_cluster_name> --user=<your_cluster_admin_user>
# kubectl config use-context ripsaw
```

We'll now apply the permissions and operator definitions.

```bash
# kubectl apply -f deploy
# kubectl apply -f resources/crds/ripsaw_v1alpha1_ripsaw_crd.yaml
# kubectl apply -f resources/operator.yaml
```

Note: we are currently experimenting with storing results in a pv attached to operator pod
and some workload pods such as [uperf](uperf.md). This will also enable us to send results
to a data store like ElasticSearch. If you'd like to try this out please use operator definition
stored in [operator_store_results](../resources/operator_store_results.yaml) after creating a pvc
as follows:
```bash
# kubectl apply -f resources/result-pvc.yaml
# kubectl apply -f resources/crds/ripsaw_v1alpha1_ripsaw_crd.yaml
# kubectl apply -f resources/operator_store_results.yaml
```

### Running workload
Now that we've deployed our operator, follow workload specific instructions to
run workloads:
* [uperf](uperf.md)
* [fio](fio.md)
* [sysbench](sysbench.md)
* [YCSB](ycsb.md)
* [Bring your own workload](byowl.md)

If you want to add a new workload please follow these [instructions](../CONTRIBUTE.md#Add-workload) to submit a PR

### Clean up
Now that we're running workloads we can cleanup by running following commands

```bash
# kubectl delete -f <your_cr_file>
# kubectl delete -f resources/crds/ripsaw_v1alpha1_ripsaw_crd.yaml
# kubectl delete -f resources/operator.yaml
# kubectl delete -f deploy
```
