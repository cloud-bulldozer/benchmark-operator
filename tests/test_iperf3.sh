#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  echo "Cleaning up iperf3"
  kubectl delete -f tests/test_crs/valid_iperf3.yaml
  delete_operator
}

trap finish EXIT

function functional_test_iperf {
  apply_operator
  kubectl apply -f tests/test_crs/valid_iperf3.yaml
  check_pods 2
  iperf_client_pod=$(kubectl get pods -l app=iperf3-bench-client -o name | cut -d/ -f2)
  kubectl wait --for=condition=Initialized "pods/$iperf_client_pod" --timeout=200s
  kubectl wait --for=condition=complete -l app=iperf3-bench-client jobs --timeout=100s
  sleep 5
  # ensuring that iperf actually ran and we can access metrics
  kubectl logs "$iperf_client_pod" --namespace ripsaw | grep "iperf Done."
  echo "iperf test: Success"
}
functional_test_iperf
