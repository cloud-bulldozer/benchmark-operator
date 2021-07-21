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
  cr=tests/test_crs/valid_byowl.yaml
  
  delete_benchmark $cr
  benchmark_name=$(get_benchmark_name $cr)
  sed -e "s/PROMETHEUS_TOKEN/${token}/g" $cr | kubectl apply -f -
  check_benchmark_for_desired_state $benchmark_name Complete 500s
  echo "BYOWL test: Success"
  delete_benchmark $cr
}

figlet $(basename $0)
functional_test_byowl
