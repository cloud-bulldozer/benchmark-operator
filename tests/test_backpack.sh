#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up backpack"
  wait_clean
}

trap error ERR
trap finish EXIT

function functional_test_backpack {
  wait_clean
  apply_operator
  kubectl apply -f $1
  long_uuid=$(get_uuid 20)
  uuid=${long_uuid:0:8}

  if [[ $1 == "tests/test_crs/valid_backpack_daemonset.yaml" ]]
  then
    wait_for_backpack $uuid
  else
    byowl_pod=$(get_pod "app=byowl-$uuid" 300)
    wait_for "kubectl -n my-ripsaw wait --for=condition=Initialized pods/$byowl_pod --timeout=500s" "500s" $byowl_pod
    wait_for "kubectl -n my-ripsaw  wait --for=condition=complete -l app=byowl-$uuid jobs --timeout=500s" "500s" $byowl_pod
  fi
  
  indexes="cpu_vulnerabilities-metadata cpuinfo-metadata dmidecode-metadata k8s_configmaps-metadata k8s_namespaces-metadata k8s_nodes-metadata k8s_pods-metadata lspci-metadata meminfo-metadata sysctl-metadata"
  if check_es "${long_uuid}" "${indexes}"
  then
    echo "Backpack test: Success"
  else
    echo "Failed to find data in ES"
    exit 1
  fi
}

figlet $(basename $0)
functional_test_backpack tests/test_crs/valid_backpack_daemonset.yaml
functional_test_backpack tests/test_crs/valid_backpack_init.yaml
