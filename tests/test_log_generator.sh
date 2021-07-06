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
  delete_benchmark $cr
  benchmark_name=$(get_benchmark_name $cr)
  echo "Performing: ${test_name}"
  kubectl apply -f ${cr}
  long_uuid=$(get_uuid $benchmark_name)
  uuid=${long_uuid:0:8}

  log_gen_pod=$(get_pod "app=log-generator-$uuid" 300)
  check_benchmark_for_desired_state $benchmark_name Complete 500s

  index="log-generator-results"
  if check_es "${long_uuid}" "${index}"
  then
    echo "${test_name} test: Success"
  else
    echo "Failed to find data for ${test_name} in ES"
    kubectl logs "$log_gen_pod" -n benchmark-operator
    exit 1
  fi
  delete_benchmark $cr
}

figlet $(basename $0)
functional_test_log_generator "Log Generator" tests/test_crs/valid_log_generator.yaml
