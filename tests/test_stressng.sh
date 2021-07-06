#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh


function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi
  echo "Cleaning up stressng"
  wait_clean
}

trap finish EXIT

function functional_test_stressng {
  token=$(oc -n openshift-monitoring sa get-token prometheus-k8s)
  cr=tests/test_crs/valid_stressng.yaml
  delete_benchmark $cr
  benchmark_name=$(get_benchmark_name $cr)
  sed -e "s/PROMETHEUS_TOKEN/${token}/g" $cr | kubectl apply -f -
  long_uuid=$(get_uuid $benchmark_name)
  uuid=${long_uuid:0:8}

  # Wait for the workload pod to run the actual workload
  stressng_workload_pod=$(get_pod "app=stressng_workload-$uuid" 300)
  check_benchmark_for_desired_state $benchmark_name Complete 500s


  index="ripsaw-stressng-results"
  if check_es "${long_uuid}" "${index}"
  then
    echo "StressNG test: Success"
  else
    echo "Failed to find data for StressNG test in ES"
    kubectl logs "$stressng_workload_pod" --namespace benchmark-operator
    exit 1
  fi

  delete_benchmark $cr
}

figlet $(basename $0)
functional_test_stressng
