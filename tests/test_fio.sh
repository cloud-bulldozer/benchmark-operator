#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  echo "Cleaning up Fio"
  kubectl delete -f tests/test_crs/valid_fio.yaml
  delete_operator
}

trap finish EXIT

function functional_test_uperf {
  apply_operator
  # Instead of applying the cr, we should create different crs and
  kubectl apply -f tests/test_crs/valid_fio.yaml
  sleep 30
  fio_pod=$(kubectl get pods -l app=fio-bench-server -o name | cut -d/ -f2)
  kubectl wait --for=condition=Initialized "pods/$fio_pod" --timeout=200s
  kubectl wait --for=condition=Ready "pods/$fio_pod" --timeout=200s
  # ensuring the run has actually happened
  kubectl logs "$fio_pod" | grep "Run status"
}

functional_test_uperf
