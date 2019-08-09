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
  figlet $(basename $0)
  apply_operator
  kubectl apply -f tests/test_crs/valid_uperf.yaml
  pod_count 'type=uperf-bench-server' 1 600
  uperf_client_pod=$(get_pod 'app=uperf-bench-client' 600)
  wait_for "kubectl -n my-ripsaw wait --for=condition=Initialized pods/$uperf_client_pod --timeout=400s" "400s" $uperf_client_pod
  wait_for "kubectl -n my-ripsaw wait --for=condition=complete -l app=uperf-bench-client jobs --timeout=1000s" "1000s" $uperf_client_pod
  #check_log $uperf_client_pod "Success"
  # This is for the operator playbook to finish running
  sleep 30

  # ensuring that uperf actually ran and we can access metrics
  kubectl logs "$uperf_client_pod" --namespace my-ripsaw | grep Success
  echo "Uperf test: Success"
}
functional_test_uperf
