#!/usr/bin/env bash
set -xeo pipefail

function finish {
  echo "Exiting after cleanup"
  kubectl delete -f test_crs/valid_uperf.yaml
  kubectl delete -f deploy/operator.yaml
  kubectl delete -f deploy/crds/bench_v1alpha1_bench_crd.yaml
  kubectl delete -f deploy/service_account.yaml
  kubectl delete -f deploy/role_binding.yaml
  kubectl delete -f deploy/role.yaml
}

trap finish EXIT

kubectl apply -f deploy/role.yaml
kubectl apply -f deploy/role_binding.yaml
kubectl apply -f deploy/service_account.yaml
kubectl apply -f deploy/crds/bench_v1alpha1_bench_crd.yaml

operator-sdk build quay.io/rht_perf_ci/benchmark-operator

docker push quay.io/rht_perf_ci/benchmark-operator

sed -i 's|          image: *|          image: quay.io/rht_perf_ci/benchmark-operator:latest # |' deploy/operator.yaml
kubectl apply -f deploy/operator.yaml

# Instead of applying the cr, we should create different crs and
kubectl apply -f test_crs/valid_uperf.yaml


# All of this currently works because we launch a single pair, we'll need to
# make changes so we dont assume just one is running
# we could wait for the uperf-client to launch which we'll have to figure soon
# something like app=uperf-bench-client
sleep 30
# This won't work as we will need to get pod name that'll launch before we wait
# for it
uperf_client_pod=$(kubectl get pods -l app=uperf-bench-client -o name | cut -d/ -f2)
# This doesn't work for some reason now
# kubectl wait --for=condition=Ready "pod/${uperf_client_pod}" --timeout=100s
sleep 150
# ensuring the run has actually happened
# temporarily disabling until #10 gets merged
kubectl get pods -l name=benchmark-operator -o name | cut -d/ -f2 | xargs -I{} kubectl exec {} -- cat /tmp/current_run

# ensuring that uperf actually ran and we can access metrics
kubectl logs "$uperf_client_pod" | grep Success
