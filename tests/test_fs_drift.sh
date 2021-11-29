#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up fs_drift"
  wait_clean
}


trap error ERR
trap finish EXIT

function functional_test_fs_drift {
  test_name=$1
  cr=$2
  delete_benchmark $cr
  echo "Performing: ${test_name}"
  benchmark_name=$(get_benchmark_name $cr)
  token=$(oc -n openshift-monitoring sa get-token prometheus-k8s)
  sed -e "s/PROMETHEUS_TOKEN/${token}/g" ${cr} | kubectl apply -f -
  long_uuid=$(get_uuid $benchmark_name)
  uuid=${long_uuid:0:8}
  fsdrift_pod=$(get_pod "app=fs_drift-benchmark-$uuid" 300)
  check_benchmark_for_desired_state $benchmark_name Complete 600s
  indexes="ripsaw-fs_drift-results ripsaw-fs_drift-rsptimes ripsaw-fs_drift-rates-over-time"
  if check_es "${long_uuid}" "${indexes}"
  then
    echo "${test_name} test: Success"
  else
    echo "Failed to find data for ${test_name} in ES"
    kubectl logs "$fsdrift_pod" -n benchmark-operator
    exit 1
  fi
  delete_benchmark $cr
}

figlet $(basename $0)
functional_test_fs_drift "fs_drift" tests/test_crs/valid_fs_drift.yaml
functional_test_fs_drift "fs_drift hostpath" tests/test_crs/valid_fs_drift_hostpath.yaml
