#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  echo "Cleaning up Fio"
  kubectl delete -f tests/test_crs/valid_fiod.yaml
  delete_operator
}

trap finish EXIT

function functional_test_fio {
  figlet $(basename $0)
  apply_operator
  kubectl apply -f tests/test_crs/valid_fiod.yaml
  pod_count 'app=fio-benchmark' 2 600
  fio_pod=$(get_pod 'app=fiod-client' 600)
  wait_for "kubectl wait --for=condition=Initialized pods/$fio_pod --namespace my-ripsaw --timeout=400s" "400s" $fio_pod
  wait_for "kubectl wait --for=condition=complete -l app=fiod-client jobs --namespace my-ripsaw --timeout=1000s" "1000s" $fio_pod
  sleep 30
  # ensuring the run has actually happened
  kubectl logs "$fio_pod" --namespace my-ripsaw | grep "fio has successfully finished sample"
  echo "Fio distributed test: Success"
}

functional_test_fio
