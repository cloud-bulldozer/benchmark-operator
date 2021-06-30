#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up sysbench"
  wait_clean
}

trap error ERR
trap finish EXIT

function functional_test_sysbench {
  kubectl apply -f tests/test_crs/valid_sysbench.yaml
  long_uuid=$(get_uuid 20)
  uuid=${long_uuid:0:8}

  sysbench_pod=$(get_pod "app=sysbench-$uuid" 300)
  wait_for "kubectl wait --for=condition=Initialized pods/$sysbench_pod --namespace ripsaw-system --timeout=500s" "500s" $sysbench_pod
  # Higher timeout as it takes longer
  wait_for "kubectl wait --for=condition=complete -l app=sysbench-$uuid --namespace ripsaw-system jobs" "300s" $sysbench_pod
  # sleep isn't needed as the sysbench is kind: job so once it's complete we can access logs
  # ensuring the run has actually happened
  kubectl logs "$sysbench_pod" --namespace ripsaw-system | grep "execution time"
  echo "Sysbench test: Success"
}

figlet $(basename $0)
functional_test_sysbench
