#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up API load Test"
  wait_clean
}

trap error ERR
trap finish EXIT

function functional_test_api_load {
  test_name=$1
  cr=$2
  delete_benchmark $cr
  echo "Performing: ${test_name}"
  kubectl apply -f ${cr}
  benchmark_name=$(get_benchmark_name $cr)
  long_uuid=$(get_uuid $benchmark_name)
  uuid=${long_uuid:0:8}

  check_benchmark_for_desired_state $benchmark_name Complete 500s

  delete_benchmark $cr
}

figlet $(basename $0)
functional_test_api_load "API load" tests/test_crs/valid_api_load.yaml
