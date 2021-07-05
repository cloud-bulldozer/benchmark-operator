#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up byowl"
  wait_clean
}

trap error ERR
trap finish EXIT

function functional_test_byowl {
  token=$(oc -n openshift-monitoring sa get-token prometheus-k8s)
  delete_benchmark tests/test_crs/valid_byowl.yaml
  benchmark_name=$(get_benchmark_name tests/test_crs/valid_byowl.yaml)
  sed -e "s/PROMETHEUS_TOKEN/${token}/g" tests/test_crs/valid_byowl.yaml | kubectl apply -f -
  check_benchmark_for_desired_state $benchmark_name Complete 500s
  echo "BYOWL test: Success"
  delete_benchmark tests/test_crs/valid_byowl.yaml
}

figlet $(basename $0)
functional_test_byowl
