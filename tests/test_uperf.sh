#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  echo "Cleaning up Uperf"
  kubectl delete -f tests/test_crs/valid_uperf.yaml
  delete_operator
}

trap finish EXIT

function functional_test_uperf {
  apply_operator
  kubectl apply -f tests/test_crs/valid_uperf.yaml
  check_pods 2
  uperf_client_pod=$(kubectl get pods -l app=uperf-bench-client -o name | cut -d/ -f2)
  kubectl wait --for=condition=Initialized "pods/$uperf_client_pod"
  kubectl wait --for=condition=complete -l app=uperf-bench-client jobs
  #check_log $uperf_client_pod "Success"
  # This is for the operator playbook to finish running
  sleep 5

  # ensuring that uperf actually ran and we can access metrics
  kubectl logs "$uperf_client_pod" --namespace ripsaw | grep Success
  echo "Uperf test: Success"
}
functional_test_uperf
