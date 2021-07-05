#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up Scale Test"
  kubectl delete -f resources/scale_role.yaml --ignore-not-found
  wait_clean
}

trap error ERR
trap finish EXIT

function functional_test_scale_openshift {
  test_name=$1
  cr=$2
  benchmark_name=$(get_benchmark_name $cr)
  delete_benchmark $cr
  # Apply scale role and service account
  kubectl apply -f resources/scale_role.yaml
  
  echo "Performing: ${test_name}"
  kubectl apply -f ${cr}
  long_uuid=$(get_uuid $benchmark_name)
  uuid=${long_uuid:0:8}

  scale_pod=$(get_pod "app=scale-$uuid" 300)
  wait_for "kubectl -n benchmark-operator wait --for=condition=Initialized -l app=scale-$uuid pods --timeout=300s" "300s" $scale_pod
  wait_for "kubectl wait -n benchmark-operator --for=condition=complete -l app=scale-$uuid jobs --timeout=500s" "500s" $scale_pod

  index="openshift-cluster-timings"
  if check_es "${long_uuid}" "${index}"
  then
    echo "${test_name} test: Success"
  else
    echo "Failed to find data for ${test_name} in ES"
    kubectl logs "$scale_pod" -n benchmark-operator
    exit 1
  fi
  kubectl delete -f ${cr}
}

figlet $(basename $0)
functional_test_scale_openshift "Scale Up" tests/test_crs/valid_scale_up.yaml
functional_test_scale_openshift "Scale Down" tests/test_crs/valid_scale_down.yaml
