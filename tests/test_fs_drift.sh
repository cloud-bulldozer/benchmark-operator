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
  uuid=$(get_uuid 20)
  
  wait_for_backpack $uuid

  count=0
  while [[ $count -lt 24 ]]
  do
    if [[ `kubectl get pods -l app=fs-drift-benchmark-$uuid --namespace my-ripsaw -o name | cut -d/ -f2 | grep client` ]]
    then
      fsdrift_pod=$(kubectl get pods -l app=fs-drift-benchmark-$uuid --namespace my-ripsaw -o name | cut -d/ -f2 | grep client)
      count=30
    fi
    if [[ $count -ne 30 ]]
    then
      sleep 5
      count=$((count + 1))
    fi
  done

  echo fsdrift_pod $fs_drift_pod
  wait_for "kubectl wait --for=condition=Initialized pods/$fsdrift_pod \
    --namespace my-ripsaw --timeout=200s" "200s" $fsdrift_pod
  wait_for "kubectl wait --for=condition=complete -l app=fs-drift-benchmark-$uuid jobs \
    --namespace my-ripsaw --timeout=100s" "200s" $fsdrift_pod
  sleep 5
  # ensuring the run has actually happened
  kubectl logs "$fsdrift_pod" --namespace my-ripsaw | grep "RUN STATUS"
  if [ $? = 0 ] ; then
    echo "fs-drift test: Success" 
  else 
    echo fs-drift test FAILURE 
    exit 1 
  fi
}

functional_test_fs_drift
