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
  apply_operator
  kubectl apply -f tests/test_crs/valid_byowl.yaml
  check_pods 1
  byowl_pod=$(kubectl get pods -l app=byowl -o name | cut -d/ -f2)
  kubectl wait --for=condition=Initialized "pods/$byowl_pod"
  kubectl wait --for=condition=complete -l app=byowl jobs
  kubectl logs "$byowl_pod" | grep "Test"
  echo "BYOWL test: Success"
}

functional_test_byowl
