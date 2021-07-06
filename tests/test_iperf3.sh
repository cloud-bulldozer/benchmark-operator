#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up iperf3"
  wait_clean
}

trap error ERR
trap finish EXIT

function functional_test_iperf {
  echo "Performing iperf3: ${1}"
  token=$(oc -n openshift-monitoring sa get-token prometheus-k8s)
  cr=tests/test_crs/valid_iperf3.yaml
  delete_benchmark $cr
  benchmark_name=$(get_benchmark_name $cr)
  sed -e "s/PROMETHEUS_TOKEN/${token}/g" -e "s/hostnetwork:.*/${1}/g" $cr | kubectl apply -f -
  long_uuid=$(get_uuid $benchmark_name)
  uuid=${long_uuid:0:8}

  iperf_server_pod=$(get_pod "app=iperf3-bench-server-$uuid" 300)
  wait_for "kubectl -n benchmark-operator wait --for=condition=Initialized -l app=iperf3-bench-server-$uuid pods --timeout=300s" "300s" $iperf_server_pod
  iperf_client_pod=$(get_pod "app=iperf3-bench-client-$uuid" 300)
  check_benchmark_for_desired_state $benchmark_name Complete 600s
  sleep 5
  # ensuring that iperf actually ran and we can access metrics
  kubectl logs "$iperf_client_pod" --namespace benchmark-operator | grep "iperf Done."
  echo "iperf ${1}: Success"
  delete_benchmark $cr
}

figlet $(basename $0)
functional_test_iperf "hostnetwork: false"
functional_test_iperf "hostnetwork: true"
