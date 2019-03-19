#!/usr/bin/env bash
set -xeo pipefail
function finish {
  echo "Exiting after cleanup"
  kubectl delete -f deploy/operator.yaml
  kubectl delete -f deploy/crds/bench_v1alpha1_bench_crd.yaml
  kubectl delete -f deploy/service_account.yaml
  kubectl delete -f deploy/role_binding.yaml
  kubectl delete -f deploy/role.yaml
}

function wait_clean {
  for i in {1..30}; do
    if [ `kubectl get pods|wc -l` -ge 2 ]; then
      sleep 5
    else
      break
    fi
  done
}

trap finish EXIT

kubectl apply -f deploy/role.yaml
kubectl apply -f deploy/role_binding.yaml
kubectl apply -f deploy/service_account.yaml
kubectl apply -f deploy/crds/bench_v1alpha1_bench_crd.yaml

operator-sdk build quay.io/rht_perf_ci/benchmark-operator

docker push quay.io/rht_perf_ci/benchmark-operator

sed -i 's|          image: *|          image: quay.io/rht_perf_ci/benchmark-operator:latest # |' deploy/operator.yaml

#
# Iterate through workloads individually
#
# Test UPerf
kubectl apply -f deploy/operator.yaml
/bin/bash tests/test_uperf.sh
kubectl delete -f tests/test_crs/valid_uperf.yaml
kubectl delete -f deploy/operator.yaml

wait_clean

#
# Test FIO
kubectl apply -f deploy/operator.yaml
/bin/bash tests/test_fio.sh
kubectl delete -f tests/test_crs/valid_fio.yaml
kubectl delete -f deploy/operator.yaml

wait_clean

#
# Test all workloads
#
kubectl apply -f deploy/operator.yaml
/bin/bash tests/test_uperf.sh
/bin/bash tests/test_fio.sh
