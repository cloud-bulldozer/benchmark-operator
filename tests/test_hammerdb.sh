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
  delete_operator
}

trap finish EXIT

function functional_test_hammerdb {
  initdb_pod
  apply_operator
  kubectl apply -f tests/test_crs/valid_hammerdb.yaml
  long_uuid=$(get_uuid 20)
  uuid=${long_uuid:0:8}

  # Wait for the workload pod to run the actual workload
  hammerdb_workload_pod=$(get_pod "app=hammerdb_workload-$uuid" 300)
  kubectl wait --for=condition=Initialized "pods/$hammerdb_workload_pod" --namespace my-ripsaw --timeout=400s
  kubectl wait --for=condition=complete -l app=hammerdb_workload-$uuid --namespace my-ripsaw jobs --timeout=500s

  index="ripsaw-hammerdb-results"
  if check_es "${long_uuid}" "${index}"
  then
    echo "Hammerdb test: Success"
  else
    echo "Failed to find data for ${test_name} in ES"
    exit 1
  fi
}

functional_test_hammerdb
