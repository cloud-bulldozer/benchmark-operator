#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  echo "Cleaning up byowl"
  kubectl delete -f tests/test_crs/valid_byowl.yaml
  delete_operator
}

trap finish EXIT

function functional_test_byowl {
  #figlet $(basename $0)
  apply_operator
  kubectl apply -f tests/test_crs/valid_byowl.yaml
  byowl_pod=$(get_pod 'app=byowl' 300)
  kubectl -n ripsaw wait --for=condition=Initialized "pods/$byowl_pod" --timeout=200s
  kubectl -n ripsaw  wait --for=condition=complete -l app=byowl jobs
  kubectl -n ripsaw logs "$byowl_pod" | grep "Test"
  echo "BYOWL test: Success"
}

functional_test_byowl
