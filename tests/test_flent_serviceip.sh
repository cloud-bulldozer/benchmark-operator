#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up flent"
  kubectl delete -f tests/test_crs/valid_flent_serviceip.yaml
  delete_operator
}

trap error ERR
trap finish EXIT

function functional_test_flent_serviceip {
  wait_clean
  apply_operator
  kubectl apply -f tests/test_crs/valid_flent_serviceip.yaml
  uuid=$(get_uuid 20)

  pod_count "type=flent-bench-server-$uuid" 1 300
  flent_client_pod=$(get_pod "app=flent-bench-client-$uuid" 300)
  wait_for "kubectl -n my-ripsaw wait --for=condition=Initialized pods/$flent_client_pod --timeout=500s" "500s" $flent_client_pod
  wait_for "kubectl -n my-ripsaw wait --for=condition=complete -l app=flent-bench-client-$uuid jobs --timeout=300s" "300s" $flent_client_pod
  #check_log $flent_client_pod "Success"
  # This is for the operator playbook to finish running
  sleep 30
  kubectl get pods -l name=benchmark-operator --namespace my-ripsaw -o name | cut -d/ -f2 | xargs -I{} kubectl -n my-ripsaw exec {} -- cat /tmp/current_run

  # ensuring that flent actually ran and we can access metrics
  kubectl logs "$flent_client_pod" --namespace my-ripsaw | grep Success
  echo "flent test: Success"
}

figlet $(basename $0)
functional_test_flent_serviceip
