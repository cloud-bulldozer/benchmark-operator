#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  [[ $check_logs == 1 ]] && kubectl logs -l app=vegeta-benchmark-$uuid -n my-ripsaw
  echo "Cleaning up vegeta"
  wait_clean
}


trap error ERR
trap finish EXIT

function functional_test_vegeta {
  check_logs=0
  wait_clean
  apply_operator
  test_name=$1
  cr=$2
  echo "Performing: ${test_name}"
  kubectl apply -f ${cr}
  long_uuid=$(get_uuid 20)
  uuid=${long_uuid:0:8}

  pod_count "app=vegeta-benchmark-$uuid" 2 900
  wait_for "kubectl wait -n my-ripsaw --for=condition=complete -l app=vegeta-benchmark-$uuid jobs --timeout=500s" "500s"
  check_logs=1

  index="ripsaw-vegeta-results"
  if check_es "${long_uuid}" "${index}"
  then
    echo "${test_name} test: Success"
  else
    echo "Failed to find data for ${test_name} in ES"
  fi
}

figlet $(basename $0)
functional_test_vegeta "Vegeta benchmark" tests/test_crs/valid_vegeta.yaml
functional_test_vegeta "Vegeta benchmark hostnetwork" tests/test_crs/valid_vegeta_hostnetwork.yaml
