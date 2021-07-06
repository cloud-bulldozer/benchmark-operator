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
  test_name=$1
  cr=$2
  delete_benchmark $cr
  echo "Performing: ${test_name}"
  benchmark_name=$(get_benchmark_name $cr)
  token=$(oc -n openshift-monitoring sa get-token prometheus-k8s)
  sed -e "s/PROMETHEUS_TOKEN/${token}/g" ${cr} | kubectl apply -f -
  long_uuid=$(get_uuid $benchmark_name)
  uuid=${long_uuid:0:8}

  check_benchmark_for_desired_state $benchmark_name Complete 800s

  index="ripsaw-flent-results"
  if check_es "${long_uuid}" "${index}"
  then
    echo "${test_name} test: Success"
  else
    echo "Failed to find data for ${test_name} in ES"
    kubectl logs "$flent_client_pod" -n benchmark-operator
    exit 1
  fi
  delete_benchmark $cr
}

figlet $(basename $0)
functional_test_flent "Flent without resources definition" tests/test_crs/valid_flent.yaml
functional_test_flent "Flent with resources definition" tests/test_crs/valid_flent_resources.yaml
