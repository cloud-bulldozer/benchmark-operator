#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  echo "Cleaning up sysbench"
  kubectl delete -f tests/test_crs/valid_sysbench.yaml
  delete_operator
}

trap finish EXIT

function functional_test_sysbench {
  figlet $(basename $0)
  apply_operator
  kubectl apply -f tests/test_crs/valid_sysbench.yaml
  sysbench_pod=$(get_pod 'app=sysbench' 300)
  kubectl wait --for=condition=Initialized "pods/$sysbench_pod" --namespace my-ripsaw --timeout=200s
  # Higher timeout as it takes longer
  kubectl wait --for=condition=complete -l app=sysbench --namespace my-ripsaw jobs
  # sleep isn't needed as the sysbench is kind: job so once it's complete we can access logs
  # ensuring the run has actually happened
  kubectl logs "$sysbench_pod" --namespace my-ripsaw | grep "execution time"
  echo "Sysbench test: Success"
}

functional_test_sysbench
