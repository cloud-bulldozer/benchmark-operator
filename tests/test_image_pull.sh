#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up Image Pull Test"
  wait_clean
}

trap error ERR
trap finish EXIT

function functional_test_image_pull {
  test_name=$1
  cr=$2
  delete_benchmark $cr
  echo "Performing: ${test_name}"
  kubectl apply -f ${cr}
  benchmark_name=$(get_benchmark_name $cr)
  long_uuid=$(get_uuid $benchmark_name)
  uuid=${long_uuid:0:8}

  check_benchmark_for_desired_state $benchmark_name Complete 500s

  index="image-pull-results"
  if check_es "${long_uuid}" "${index}"
  then
    echo "${test_name} test: Success"
  else
    echo "Failed to find data for ${test_name} in ES"
    exit 1
  fi
  delete_benchmark $cr
}

figlet $(basename $0)
functional_test_image_pull "Image Pull" tests/test_crs/valid_image_pull.yaml
