#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up byowl"
  kubectl delete -f tests/test_crs/valid_byowl.yaml
  delete_operator
}

trap error ERR
trap finish EXIT

function functional_test_byowl {
  figlet $(basename $0)
  apply_operator
  kubectl apply -f tests/test_crs/valid_byowl.yaml
  byowl_pod=$(get_pod 'app=byowl' 600)
  wait_for "kubectl -n my-ripsaw wait --for=condition=Initialized pods/$byowl_pod --timeout=400s" "400s" $byowl_pod
  wait_for "kubectl -n my-ripsaw  wait --for=condition=complete -l app=byowl jobs --timeout=600s" "600s" $byowl_pod
  kubectl -n my-ripsaw logs "$byowl_pod" | grep "Test"
  echo "BYOWL test: Success"
}

functional_test_byowl
