## Installation
This guide uses minikube version v1.5.2+ as the local Kubernetes cluster
and quay.io for the public registry. We also test on crc version v1.7.0+.
`kubectl` is used but can be substituted with `oc`.

### Tested versions
* [OpenShift® Container Platform](https://www.openshift.com/products/container-platform/)
  * Tested on: 4.3 and later
* [kubernetes](https://kubernetes.io/)
  * Tested on: 1.16.2 and later

Note:
* Experimental tag refers to some workloads that might be functioning
* To use versions of Openshift and kubernetes prior to 4.3 and 1.16.2 respectively, please use version 0.0.2 of ripsaw

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

Note: If you're on a vanilla k8s distribution, then you can also deploy Ripsaw through
      operatorhub.io, please check [ripsaw in operatorhub](https://operatorhub.io/operator/ripsaw) for more details.

First we'll need to clone the operator:

```bash
# git clone https://github.com/cloud-bulldozer/benchmark-operator.git
# cd ripsaw
# export KUBECONFIG=<your_kube_config> # if not already done
```

We try to maintain all resources created/required by ripsaw in the namespace `my-ripsaw`,
as this would be the namespace, ripsaw would be installed into if deployed through operatorhub.io.

Note: But in case you've a specific usecase where you want the resources to be in a different namespace, you'll just need to edit the namespace in deploy/
as well as the operator definition.

But for sake of the documentation, let's proceed with the namespace `my-ripsaw`

so we'll create the namespace as follows

```bash
# kubectl apply -f resources/namespace.yaml
```

or if you're used to `oc` it'd be `oc new-project my-ripsaw` and `oc project my-ripsaw`

We'll now apply the permissions and operator definitions.

```bash
# kubectl apply -f deploy
# kubectl apply -f resources/crds/ripsaw_v1alpha1_ripsaw_crd.yaml
# kubectl apply -f resources/operator.yaml
```

### Running workload
Now that we've deployed our operator, follow workload specific instructions to
run workloads:
* [uperf](uperf.md)
* [fio](fio_distributed.md)
* [sysbench](sysbench.md)
* [YCSB](ycsb.md)
* [Bring your own workload](byowl.md)
* [pgbench](pgbench.md)
* [fs-drift](fs-drift.md)
* [servicemesh](servicemesh.md)
* [cyclictest](cyclictest.md)
* [oslat](oslat.md)

If you want to add a new workload please follow these [instructions](../CONTRIBUTE.md#Add-workload) to submit a PR

### Clean up
Now that we're running workloads we can cleanup by running following commands

```bash
# kubectl delete -f <your_cr_file>
# kubectl delete -f resources/crds/ripsaw_v1alpha1_ripsaw_crd.yaml
# kubectl delete -f resources/operator.yaml
# kubectl delete -f deploy
```

## running CI

If you want to run CI on your laptop as part of developing a PR, you may want to use your own image location and account (i.e. your
own image repository account).   To do this, set 2 environment variables:

* RIPSAW_CI_IMAGE_LOCATION - host where image repository lives (default is quay.io)
* RIPSAW_CI_IMAGE_ACCOUNT - user account (default is rht_perf_ci).

This allows you to have the CI run on your own private image built with your PR.  This assumes that your benchmark's CI
script in tests/ utilizes the common code in tests/common.sh to launch ripsaw.

You can modify your ripsaw image to use a test version of your benchmark image as well.  For examples, see workload.yml.j2 files in the roles/ tree and look for the image: tag.
