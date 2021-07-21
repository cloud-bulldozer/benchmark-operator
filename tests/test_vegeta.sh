#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  [[ $check_logs == 1 ]] && kubectl logs -l app=vegeta-benchmark-$uuid -n benchmark-operator
  echo "Cleaning up vegeta"
  wait_clean
}


trap error ERR
trap finish EXIT

function functional_test_vegeta {
  check_logs=0
  test_name=$1
  cr=$2
  benchmark_name=$(get_benchmark_name $cr)
  delete_benchmark $cr
  echo "Performing: ${test_name}"
  token=$(oc -n openshift-monitoring sa get-token prometheus-k8s)
  sed -e "s/PROMETHEUS_TOKEN/${token}/g" ${cr} | kubectl apply -f -
  long_uuid=$(get_uuid $benchmark_name)
  uuid=${long_uuid:0:8}
  check_benchmark_for_desired_state $benchmark_name Complete 500s
  check_logs=1

  index="ripsaw-vegeta-results"
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
functional_test_vegeta "Vegeta benchmark" tests/test_crs/valid_vegeta.yaml
functional_test_vegeta "Vegeta benchmark hostnetwork" tests/test_crs/valid_vegeta_hostnetwork.yaml
