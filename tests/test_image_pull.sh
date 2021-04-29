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
  wait_clean
  apply_operator
  test_name=$1
  cr=$2
  
  echo "Performing: ${test_name}"
  kubectl apply -f ${cr}
  long_uuid=$(get_uuid 20)
  uuid=${long_uuid:0:8}

  pod_count "app=image-pull-$uuid" 2 300
  wait_for "kubectl wait -n my-ripsaw --for=condition=complete -l app=image-pull-$uuid jobs --timeout=500s" "500s"

  index="image-pull-results"
  if check_es "${long_uuid}" "${index}"
  then
    echo "${test_name} test: Success"
  else
    echo "Failed to find data for ${test_name} in ES"
    exit 1
  fi
  kubectl delete -f ${cr}
}

figlet $(basename $0)
functional_test_image_pull "Image Pull" tests/test_crs/valid_image_pull.yaml
