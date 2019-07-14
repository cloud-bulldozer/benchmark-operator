#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  echo "Cleaning up Smallfile"
  kubectl delete -f tests/test_crs/valid_smallfile.yaml
  delete_operator
}

trap finish EXIT

function functional_test_smallfile {
  apply_operator
  kubectl apply -f tests/test_crs/valid_smallfile.yaml
  sleep 15
  smallfile_pod=$(kubectl get pods -l app=smallfile-benchmark --namespace my-ripsaw -o name | cut -d/ -f2 | grep client)
  echo smallfile_pod $smallfile_pod
  kubectl wait --for=condition=Initialized "pods/$smallfile_pod" --namespace my-ripsaw --timeout=200s
  kubectl wait --for=condition=complete -l app=smallfile-benchmark jobs --namespace my-ripsaw --timeout=100s
  sleep 30
  # ensuring the run has actually happened
  kubectl logs "$smallfile_pod" --namespace my-ripsaw | grep "RUN STATUS"
  echo "Smallfile test: Success"
}

functional_test_smallfile
