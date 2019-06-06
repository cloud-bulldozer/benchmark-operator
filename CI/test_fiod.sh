#!/usr/bin/env bash
set -xeo pipefail

source CI/common.sh

function finish {
  echo "Cleaning up Fio"
  kubectl delete -f CI/test_crs/valid_fiod.yaml
  delete_operator
}

trap finish EXIT

function functional_test_fio {
  apply_operator
  kubectl apply -f CI/test_crs/valid_fiod.yaml
  check_pods 3
  fio_pod=$(kubectl get pods -l app=fiod-client --namespace ripsaw -o name | cut -d/ -f2)
  kubectl wait --for=condition=Initialized "pods/$fio_pod" --namespace ripsaw --timeout=200s
  kubectl wait --for=condition=complete -l app=fiod-client jobs --namespace ripsaw --timeout=300s
  sleep 30
  # ensuring the run has actually happened
  kubectl logs "$fio_pod" --namespace ripsaw | grep "Run status"
  echo "Fio distributed test: Success"
}

functional_test_fio
