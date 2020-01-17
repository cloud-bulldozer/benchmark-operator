#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

trap error ERR
trap wait_clean EXIT

function functional_test_fs_drift {
  apply_operator
  test_name=$1
  cr=$2
  echo "Performing: ${test_name}"
  kubectl apply -f ${cr}
  uuid=$(get_uuid 20)
  wait_for_backpack $uuid
  count=0
  while [[ $count -lt 24 ]]; do
    if [[ `kubectl get pods -l app=fs-drift-benchmark-$uuid --namespace my-ripsaw -o name | cut -d/ -f2 | grep client` ]]; then
      fsdrift_pod=$(kubectl get pods -l app=fs-drift-benchmark-$uuid --namespace my-ripsaw -o name | cut -d/ -f2 | grep client)
      count=30
    fi
    if [[ $count -ne 30 ]]; then
      sleep 5
      count=$((count + 1))
    fi
  done
  echo fsdrift_pod $fs_drift_pod
  wait_for "kubectl wait --for=condition=Initialized pods/$fsdrift_pod -n my-ripsaw --timeout=200s" "200s" $fsdrift_pod
  wait_for "kubectl wait --for=condition=complete -l app=fs-drift-benchmark-$uuid jobs -n my-ripsaw --timeout=100s" "200s" $fsdrift_pod
  # Print logs and check status
  kubectl logs "$fsdrift_pod" -n my-ripsaw
  kubectl logs "$fsdrift_pod" -n my-ripsaw | grep "RUN STATUS"
  echo "${test_name} test: Success"
  wait_clean
}

figlet $(basename $0)
functional_test_fs_drift "fs-drift" tests/test_crs/valid_fs_drift.yaml
functional_test_fs_drift "fs-drift hostpath" tests/test_crs/valid_fs_drift_hostpath.yaml
