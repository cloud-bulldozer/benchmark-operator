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
  apply_operator
  sleep 5
  kubectl apply -f tests/test_crs/valid_sysbench.yaml
  check_pods 1
  sysbench_pod=$(kubectl get pods -l app=sysbench -o name | cut -d/ -f2)
  kubectl wait --for=condition=Initialized "pods/$sysbench_pod" --timeout=200s
  kubectl wait --for=condition=complete -l app=sysbench jobs
  # ensuring the run has actually happened
  kubectl logs "$sysbench_pod" | grep "execution time"
  echo "Sysbench test: Success"
}

functional_test_sysbench
