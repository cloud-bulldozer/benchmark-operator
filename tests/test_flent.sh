#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up Flent"
  wait_clean
}

trap error ERR
trap finish EXIT

function functional_test_flent {
  wait_clean
  apply_operator
  test_name=$1
  cr=$2
  echo "Performing: ${test_name}"
  kubectl apply -f ${cr}
  long_uuid=$(get_uuid 20)
  uuid=${long_uuid:0:8}

  pod_count "type=flent-bench-server-$uuid" 1 900
  flent_server_pod=$(get_pod "app=flent-bench-server-0-$uuid" 300)
  wait_for "kubectl -n my-ripsaw wait --for=condition=Initialized -l app=flent-bench-server-0-$uuid pods --timeout=300s" "300s" $flent_server_pod
  flent_client_pod=$(get_pod "app=flent-bench-client-$uuid" 900)
  wait_for "kubectl wait -n my-ripsaw --for=condition=Initialized pods/$flent_client_pod --timeout=500s" "500s" $flent_client_pod
  wait_for "kubectl wait -n my-ripsaw --for=condition=complete -l app=flent-bench-client-$uuid jobs --timeout=500s" "500s" $flent_client_pod

  index="ripsaw-flent-results"
  if check_es "${long_uuid}" "${index}"
  then
    echo "${test_name} test: Success"
  else
    echo "Failed to find data for ${test_name} in ES"
    kubectl logs "$flent_client_pod" -n my-ripsaw
    exit 1
  fi
}

figlet $(basename $0)
functional_test_flent "Flent without resources definition" tests/test_crs/valid_flent.yaml
functional_test_flent "Flent with resources definition" tests/test_crs/valid_flent_resources.yaml
