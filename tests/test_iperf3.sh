#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi
  
  echo "Cleaning up iperf3"
  kubectl delete -f tests/test_crs/valid_iperf3.yaml
  delete_operator
}

trap error ERR
trap finish EXIT

function functional_test_iperf {
  figlet $(basename $0)
  apply_operator
  kubectl apply -f tests/test_crs/valid_iperf3.yaml
  pod_count 'app=iperf3-bench-server' 1 600
  iperf_client_pod=$(get_pod 'app=iperf3-bench-client' 600)
  wait_for "kubectl -n my-ripsaw wait --for=condition=Initialized pods/$iperf_client_pod --timeout=400s" "400s" $iperf_client_pod
  wait_for "kubectl -n my-ripsaw wait --for=condition=complete -l app=iperf3-bench-client jobs --timeout=200s" "200s" $iperf_client_pod
  sleep 5
  # ensuring that iperf actually ran and we can access metrics
  kubectl logs "$iperf_client_pod" --namespace my-ripsaw | grep "iperf Done."
  echo "iperf test: Success"
}

functional_test_iperf
