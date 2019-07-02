#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  echo "Cleaning up Fio"
  kubectl delete -f tests/test_crs/valid_fio.yaml
  delete_operator
}

trap finish EXIT

function functional_test_fio {
  #figlet $(basename $0)
  apply_operator
  kubectl apply -f tests/test_crs/valid_fio.yaml
  fio_pod=$(get_pod 'app=fio-benchmark' 300)
  kubectl wait --for=condition=Initialized "pods/$fio_pod" --namespace ripsaw --timeout=200s
  kubectl wait --for=condition=complete -l app=fio-benchmark jobs --namespace ripsaw --timeout=100s
  sleep 30
  # ensuring the run has actually happened
  kubectl logs "$fio_pod" --namespace ripsaw | grep "Run status"
  echo "Fio test: Success"
}

functional_test_fio
