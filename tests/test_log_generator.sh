#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up Log Generator Test"
  wait_clean
}

trap error ERR
trap finish EXIT

function functional_test_log_generator {
  test_name=$1
  cr=$2
  
  echo "Performing: ${test_name}"
  kubectl apply -f ${cr}
  long_uuid=$(get_uuid 20)
  uuid=${long_uuid:0:8}

  log_gen_pod=$(get_pod "app=log-generator-$uuid" 300)
  wait_for "kubectl -n ripsaw-system wait --for=condition=Initialized -l app=log-generator-$uuid pods --timeout=300s" "300s" $log_gen_pod
  wait_for "kubectl wait -n ripsaw-system --for=condition=complete -l app=log-generator-$uuid jobs --timeout=300s" "300s" $log_gen_pod

  index="log-generator-results"
  if check_es "${long_uuid}" "${index}"
  then
    echo "${test_name} test: Success"
  else
    echo "Failed to find data for ${test_name} in ES"
    kubectl logs "$log_gen_pod" -n ripsaw-system
    exit 1
  fi
  kubectl delete -f ${cr}
}

figlet $(basename $0)
functional_test_log_generator "Log Generator" tests/test_crs/valid_log_generator.yaml
