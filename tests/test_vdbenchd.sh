#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up Vdbench"
  kubectl delete -f tests/test_crs/valid_vdbenchd.yaml
  delete_operator
}

trap error ERR
trap finish EXIT

function functional_test_vdbench {
  figlet $(basename $0)
  apply_operator
  kubectl apply -f tests/test_crs/valid_vdbenchd.yaml
  uuid=$(get_uuid 20)
  
  wait_for_backpack $uuid

  pod_count "app=vdbench-benchmark-$uuid" 2 300
  vdbench_pod=$(get_pod "app=vdbenchd-client-$uuid" 300)
  wait_for "kubectl wait --for=condition=Initialized pods/$vdbench_pod --namespace my-ripsaw --timeout=200s" "200s" $vdbench_pod
  wait_for "kubectl wait --for=condition=complete -l app=vdbenchd-client-$uuid jobs --namespace my-ripsaw --timeout=500s" "500s" $vdbench_pod
  sleep 30
  # ensuring the run has actually happened
  kubectl logs "$vdbench_pod" --namespace my-ripsaw | grep "Test Run Finished"
  echo "VDBench test: Success"
}

functional_test_vdbench
