#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up backpack"
  kubectl delete -f tests/test_crs/valid_backpack.yaml
  delete_operator
}

trap error ERR
trap finish EXIT

function functional_test_backpack {
  figlet $(basename $0)
  apply_operator
  kubectl apply -f tests/test_crs/valid_backpack.yaml
  long_uuid=$(get_uuid 20)
  uuid=${long_uuid:0:8}

  wait_for_backpack $uuid
  
  indexes="cpu_vulnerabilities-metadata cpuinfo-metadata dmidecode-metadata k8s_configmaps-metadata k8s_namespaces-metadata k8s_nodes-metadata k8s_pods-metadata lspci-metadata meminfo-metadata sysctl-metadata"
  if check_es "${long_uuid}" "${indexes}"
  then
    echo "Backpack test: Success"
  else
    exit 1
    echo "Faled to find data in ES"
  fi
}

functional_test_backpack
