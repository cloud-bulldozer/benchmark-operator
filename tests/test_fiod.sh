#!/usr/bin/env bash
set -xeEo pipefail

source common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up Fio"
  kubectl delete -f tests/test_crs/valid_fiod.yaml
  delete_operator
}

trap error ERR
trap finish EXIT

function functional_test_fio {
  figlet $(basename $0)
  apply_operator
  kubectl apply -f tests/test_crs/valid_fiod.yaml
  uuid=$(get_uuid 20)
  pod_count "app=fio-benchmark-$uuid" 2 300
  fio_pod=$(get_pod "app=fiod-client-$uuid" 300)
  wait_for "kubectl wait --for=condition=Initialized pods/$fio_pod --namespace my-ripsaw --timeout=200s" "200s" $fio_pod
  wait_for "kubectl wait --for=condition=complete -l app=fiod-client-$uuid jobs --namespace my-ripsaw --timeout=500s" "500s" $fio_pod
  sleep 30
  # ensuring the run has actually happened
  kubectl logs "$fio_pod" --namespace my-ripsaw | grep "fio has successfully finished sample"
  echo "Fio distributed test: Success"
}

functional_test_fio
