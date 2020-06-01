#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up fio"
  wait_clean
}

trap error ERR
trap finish EXIT

function functional_test_fio {
  apply_operator
  test_name=$1
  cr=$2
  echo "Performing: ${test_name}"
  kubectl apply -f ${cr}
  long_uuid=$(get_uuid 20)
  uuid=${long_uuid:0:8}

  pod_count "app=fio-benchmark-$uuid" 2 300  
  wait_for "kubectl -n my-ripsaw wait --for=condition=Initialized -l app=fio-benchmark-$uuid pods --timeout=300s" "300s"
  fio_pod=$(get_pod "app=fiod-client-$uuid" 300)
  wait_for "kubectl wait --for=condition=Initialized pods/$fio_pod -n my-ripsaw --timeout=500s" "500s" $fio_pod
  wait_for "kubectl wait --for=condition=complete -l app=fiod-client-$uuid jobs -n my-ripsaw --timeout=500s" "500s" $fio_pod

  index="ripsaw-fio-results ripsaw-fio-log ripsaw-fio-analyzed-result"
  if check_es "${long_uuid}" "${index}"
  then
    echo "${test_name} test: Success"
  else
    echo "Failed to find data for ${test_name} in ES"
    exit 1
  fi
}

figlet $(basename $0)
functional_test_fio "Fio distributed" tests/test_crs/valid_fiod.yaml
wait_clean
functional_test_fio "Fio hostpath distributed" tests/test_crs/valid_fiod_hostpath.yaml
