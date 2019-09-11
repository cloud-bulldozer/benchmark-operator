#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  echo "Cleaning up fs-drift"
  kubectl delete -f tests/test_crs/valid_fs_drift.yaml
  delete_operator
}

trap finish EXIT

function functional_test_fs_drift {
  figlet $(basename $0)
  apply_operator
  kubectl apply -f tests/test_crs/valid_fs_drift.yaml
  uuid=$(get_uuid 120)
  fsdrift_pod=$(get_pod "app=fs-drift-benchmark-$uuid" 300)
  echo fsdrift_pod $fs_drift_pod
  wait_for "kubectl wait --for=condition=Initialized pods/$fsdrift_pod \
    --namespace my-ripsaw --timeout=200s" "200s" $fsdrift_pod
  wait_for "kubectl wait --for=condition=complete -l app=fs-drift-benchmark-$uuid jobs \
    --namespace my-ripsaw --timeout=100s" "200s" $fsdrift_pod
  sleep 20
  # ensuring the run has actually happened
  kubectl logs "$fsdrift_pod" --namespace my-ripsaw | grep "RUN STATUS"
  echo "fs-drift test: Success"
}

functional_test_fs_drift
