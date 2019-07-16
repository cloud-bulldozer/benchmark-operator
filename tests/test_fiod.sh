#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  echo "Cleaning up Fio"
  kubectl delete -f tests/test_crs/valid_fiod.yaml
  delete_operator
}

trap finish EXIT

function functional_test_fio {
  #figlet $(basename $0)
  apply_operator
  kubectl apply -f tests/test_crs/valid_fiod.yaml
  pod_count 'app=fio-benchmark' 2 300
  fio_pod=$(get_pod 'app=fiod-client' 300)
  kubectl wait --for=condition=Initialized "pods/$fio_pod" --namespace my-ripsaw --timeout=200s
  kubectl wait --for=condition=complete -l app=fiod-client jobs --namespace my-ripsaw --timeout=500s
  sleep 30
  # ensuring the run has actually happened
  kubectl logs "$fio_pod" --namespace my-ripsaw | grep "succesfully finished executing for jobname"
  echo "Fio distributed test: Success"
}

functional_test_fio
