#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up Uperf"
  wait_clean
}

trap error ERR
trap finish EXIT

function functional_test_uperf {
  token=$(oc -n openshift-monitoring sa get-token prometheus-k8s)
  test_name=$1
  cr=$2
  benchmark_name=$(get_benchmark_name $cr)
  delete_benchmark $cr
  echo "Performing: ${test_name}"
  sed -e "s/PROMETHEUS_TOKEN/${token}/g" ${cr} | kubectl apply -f -
  long_uuid=$(get_uuid $benchmark_name)
  uuid=${long_uuid:0:8}
  check_benchmark_for_desired_state $benchmark_name Complete 1800s
  


  index="ripsaw-uperf-results"
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
functional_test_uperf "Uperf without resources definition" tests/test_crs/valid_uperf.yaml
functional_test_uperf "Uperf with ServiceIP" tests/test_crs/valid_uperf_serviceip.yaml
functional_test_uperf "Uperf with NodePort ServiceIP" tests/test_crs/valid_uperf_serviceip_nodeport.yaml
functional_test_uperf "Uperf with resources definition and hostNetwork" tests/test_crs/valid_uperf_resources.yaml
functional_test_uperf "Uperf with networkpolicy" tests/test_crs/valid_uperf_networkpolicy.yaml
