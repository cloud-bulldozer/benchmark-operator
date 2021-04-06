#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up fs_drift"
  wait_clean
}


trap error ERR
trap finish EXIT

function functional_test_fs_drift {
  wait_clean
  apply_operator
  test_name=$1
  cr=$2
  echo "Performing: ${test_name}"
  token=$(oc -n openshift-monitoring sa get-token prometheus-k8s)
  sed -e "s/PROMETHEUS_TOKEN/${token}/g" ${cr} | kubectl apply -f -
  long_uuid=$(get_uuid 20)
  uuid=${long_uuid:0:8}

  count=0
  while [[ $count -lt 24 ]]; do
    if [[ `kubectl get pods -l app=fs-drift-benchmark-$uuid --namespace my-ripsaw -o name | cut -d/ -f2 | grep client` ]]; then
      fsdrift_pod=$(kubectl get pods -l app=fs-drift-benchmark-$uuid --namespace my-ripsaw -o name | cut -d/ -f2 | grep client)
      count=30
    fi
    if [[ $count -ne 30 ]]; then
      sleep 5
      count=$((count + 1))
    fi
  done
  echo fsdrift_pod $fs_drift_pod
  wait_for "kubectl wait --for=condition=Initialized pods/$fsdrift_pod -n my-ripsaw --timeout=500s" "500s" $fsdrift_pod
  wait_for "kubectl wait --for=condition=complete -l app=fs-drift-benchmark-$uuid jobs -n my-ripsaw --timeout=100s" "200s" $fsdrift_pod

  indexes="ripsaw-fs-drift-results ripsaw-fs-drift-rsptimes ripsaw-fs-drift-rates-over-time"
  if check_es "${long_uuid}" "${indexes}"
  then
    echo "${test_name} test: Success"
  else
    echo "Failed to find data for ${test_name} in ES"
    kubectl logs "$fsdrift_pod" -n my-ripsaw
    exit 1
  fi
}

figlet $(basename $0)
functional_test_fs_drift "fs-drift" tests/test_crs/valid_fs_drift.yaml
functional_test_fs_drift "fs-drift hostpath" tests/test_crs/valid_fs_drift_hostpath.yaml
