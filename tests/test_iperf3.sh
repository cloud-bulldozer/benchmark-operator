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
  wait_clean
  apply_operator
  echo "Performing iperf3: ${1}"
  sed -e "s/hostnetwork:.*/${1}/g" tests/test_crs/valid_iperf3.yaml | kubectl apply -f -
  long_uuid=$(get_uuid 20)
  uuid=${long_uuid:0:8}

  iperf_server_pod=$(get_pod "app=iperf3-bench-server-$uuid" 300)
  wait_for "kubectl -n my-ripsaw wait --for=condition=Initialized -l app=iperf3-bench-server-$uuid pods --timeout=300s" "300s" $iperf_server_pod
  iperf_client_pod=$(get_pod "app=iperf3-bench-client-$uuid" 300)
  wait_for "kubectl -n my-ripsaw wait --for=condition=Initialized pods/$iperf_client_pod --timeout=500s" "500s" $iperf_client_pod
  wait_for "kubectl -n my-ripsaw wait --for=condition=complete -l app=iperf3-bench-client-$uuid jobs --timeout=100s" "100s" $iperf_client_pod
  sleep 5
  # ensuring that iperf actually ran and we can access metrics
  kubectl logs "$iperf_client_pod" --namespace my-ripsaw | grep "iperf Done."
  echo "iperf ${1}: Success"
}

figlet $(basename $0)
functional_test_iperf "hostnetwork: false"
functional_test_iperf "hostnetwork: true"
