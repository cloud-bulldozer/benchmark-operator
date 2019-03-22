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
  kubectl apply -f tests/test_crs/valid_sysbench.yaml
  sleep 15
  kubectl wait --for=condition=complete -l app=sysbench jobs --timeout=200s
  # sleep isn't needed as the sysbench is kind: job so once it's complete we can access logs
  # ensuring the run has actually happened
  kubectl logs -l app=sysbench | grep "execution time"
}

functional_test_sysbench
