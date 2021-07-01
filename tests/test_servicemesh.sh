#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up ServiceMesh"
  long_uuid=$(get_uuid 0)
  uuid=${long_uuid:0:8}
  kubectl delete --ignore-not-found=true namespace example-benchmark-controlplane-$uuid
  kubectl delete --ignore-not-found=true namespace example-benchmark-workload-$uuid
  wait_clean
}

trap error ERR
trap finish EXIT

function functional_test_servicemesh {
  delete_benchmark tests/test_crs/valid_servicemesh.yaml
  kubectl apply -f tests/test_crs/valid_servicemesh.yaml
  long_uuid=$(get_uuid 20)
  uuid=${long_uuid:0:8}

  # wait until the job appears
  count=0
  max_count=60
  while [[ $count -lt $max_count ]]
  do
    if kubectl get --namespace benchmark-operator job example-benchmark-$uuid; then
        break
    fi
    sleep 15
    count=$((count + 1))
  done

  wait_for "kubectl -n benchmark-operator wait --for=condition=complete jobs --timeout=300s example-benchmark-$uuid" "300s"

  job_pod=$(get_pod app=example-benchmark-$uuid 30)
  # ensuring that uperf actually ran and we can access metrics
  INFO=$(kubectl logs $job_pod --namespace benchmark-operator | jq .info)
  if [ -n "$INFO" ]; then
    echo "Successful: $INFO"
  else
    echo "Failed to verify benchmark results"
    exit 1
  fi
}

functional_test_servicemesh
