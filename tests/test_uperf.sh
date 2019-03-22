#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  echo "Cleaning up Uperf"
  kubectl delete -f tests/test_crs/valid_uperf.yaml
  delete_operator
}

trap finish EXIT

function functional_test_uperf {
  apply_operator
  kubectl apply -f tests/test_crs/valid_uperf.yaml
  check_pods 3
  uperf_client_pod=$(kubectl get pods -l app=uperf-bench-client -o name | cut -d/ -f2)

  kubectl wait --for=condition=Initialized "pods/$uperf_client_pod" --timeout=200s
  kubectl wait --for=condition=Ready "pods/$uperf_client_pod" --timeout=45s
  #check_log $uperf_client_pod "Success"
  # This is for the operator playbook to finish running
  sleep 30
  kubectl get pods -l name=benchmark-operator -o name | cut -d/ -f2 | xargs -I{} kubectl exec {} -- cat /tmp/current_run

  # ensuring that uperf actually ran and we can access metrics
  kubectl logs "$uperf_client_pod" | grep Success
}
functional_test_uperf
