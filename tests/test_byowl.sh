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
  wait_clean
  apply_operator
  token=$(oc -n openshift-monitoring sa get-token prometheus-k8s)
  sed -e "s/PROMETHEUS_TOKEN/${token}/g" tests/test_crs/valid_byowl.yaml | kubectl apply -f -
  long_uuid=$(get_uuid 20)
  uuid=${long_uuid:0:8}
  
  byowl_pod=$(get_pod "app=byowl-$uuid" 300)
  wait_for "kubectl -n my-ripsaw wait --for=condition=Initialized pods/$byowl_pod --timeout=500s" "500s" $byowl_pod
  wait_for "kubectl -n my-ripsaw  wait --for=condition=complete -l app=byowl-$uuid jobs --timeout=300s" "300s" $byowl_pod
  kubectl -n my-ripsaw logs "$byowl_pod" | grep "Test"
  echo "BYOWL test: Success"
}

figlet $(basename $0)
functional_test_byowl
