#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh


function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi
  echo "Cleaning up stressng"
  kubectl delete -f tests/test_crs/valid_stressng.yaml
  delete_operator
}

trap finish EXIT

function functional_test_stressng {
  wait_clean
  apply_operator
  kubectl apply -f tests/test_crs/valid_stressng.yaml
  long_uuid=$(get_uuid 20)
  uuid=${long_uuid:0:8}

  # Wait for the workload pod to run the actual workload
  stressng_workload_pod=$(get_pod "app=stressng_workload-$uuid" 300)
  kubectl wait --for=condition=Initialized "pods/$stressng_workload_pod" --namespace my-ripsaw --timeout=400s
  kubectl wait --for=condition=complete -l app=stressng_workload-$uuid --namespace my-ripsaw jobs --timeout=500s

  index="ripsaw-stressng-results"
  if check_es "${long_uuid}" "${index}"
  then
    echo "StressNG test: Success"
  else
    echo "Failed to find data for StressNG test in ES"
    kubectl logs "$stressng_workload_pod" --namespace my-ripsaw
    exit 1
  fi
}

figlet $(basename $0)
functional_test_stressng
