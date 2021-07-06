#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function initdb_pod {
  echo "Setting up a MS-SQL DB Pod"
  kubectl apply -f tests/mssql.yaml
  mssql_pod=$(get_pod "app=mssql" 300 "sql-server")
  kubectl wait --for=condition=Ready "pods/$mssql_pod" --namespace sql-server --timeout=300s
}

function finish {
  echo "Cleaning up hammerdb"
  kubectl delete -f tests/mssql.yaml 
  kubectl delete -f tests/test_crs/valid_hammerdb.yaml
  wait_clean
}

trap finish EXIT

function functional_test_hammerdb {
  initdb_pod
  token=$(oc -n openshift-monitoring sa get-token prometheus-k8s)
  cr=tests/test_crs/valid_hammerdb.yaml
  delete_benchmark $cr
  benchmark_name=$(get_benchmark_name $cr)
  sed -e "s/PROMETHEUS_TOKEN/${token}/g" $cr | kubectl apply -f -
  long_uuid=$(get_uuid $benchmark_name)
  uuid=${long_uuid:0:8}

  # Wait for the workload pod to run the actual workload
  hammerdb_workload_pod=$(get_pod "app=hammerdb_workload-$uuid" 300)
  check_benchmark_for_desired_state $benchmark_name Complete 900s

  index="ripsaw-hammerdb-results"
  if check_es "${long_uuid}" "${index}"
  then
    echo "Hammerdb test: Success"
  else
    echo "Failed to find data for HammerDB test in ES"
    kubectl logs "$hammerdb_workload_pod" --namespace benchmark-operator
    exit 1
  fi
  delete_benchmark $cr
}

figlet $(basename $0)
functional_test_hammerdb
