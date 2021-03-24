#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up Uperf"
  wait_clean
}

trap error ERR
trap finish EXIT

function functional_test_uperf {
  wait_clean
  apply_operator
  token=$(oc -n openshift-monitoring sa get-token prometheus-k8s)
  test_name=$1
  cr=$2
  echo "Performing: ${test_name}"
  sed -e "s/PROMETHEUS_TOKEN/${token}/g" ${cr} | kubectl apply -f -
  long_uuid=$(get_uuid 20)
  uuid=${long_uuid:0:8}

  pod_count "type=uperf-bench-server-$uuid" 1 900
  uperf_server_pod=$(get_pod "type=uperf-bench-server-${uuid}" 300)
  wait_for "kubectl -n my-ripsaw wait --for=condition=Initialized -l type=uperf-bench-server-${uuid} pods --timeout=300s" "300s" $uperf_server_pod
  uperf_client_pod=$(get_pod "app=uperf-bench-client-$uuid" 900)
  wait_for "kubectl wait -n my-ripsaw --for=condition=Initialized pods/$uperf_client_pod --timeout=500s" "500s" $uperf_client_pod
  wait_for "kubectl wait -n my-ripsaw --for=condition=complete -l app=uperf-bench-client-$uuid jobs --timeout=500s" "500s" $uperf_client_pod

  index="ripsaw-uperf-results"
  if check_es "${long_uuid}" "${index}"
  then
    echo "${test_name} test: Success"
  else
    echo "Failed to find data for ${test_name} in ES"
    kubectl logs "$uperf_client_pod" -n my-ripsaw
    exit 1
  fi
}

figlet $(basename $0)
functional_test_uperf "Uperf without resources definition" tests/test_crs/valid_uperf.yaml
functional_test_uperf "Uperf with ServiceIP" tests/test_crs/valid_uperf_serviceip.yaml
functional_test_uperf "Uperf with resources definition and hostNetwork" tests/test_crs/valid_uperf_resources.yaml
functional_test_uperf "Uperf with networkpolicy" tests/test_crs/valid_uperf_networkpolicy.yaml
