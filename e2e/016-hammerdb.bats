#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

ES_INDEX=ripsaw-hammerdb-results


@test "hammerdb-standard" {
  CR=hammerdb/hammerdb.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 600
  check_es
}

setup_file() {
  basic_setup
  kubectl apply -f hammerdb/sql-server.yaml
  kubectl rollout status -n sql-server deploy/mssql-deployment --timeout=60s
}

teardown_file() {
  kubectl delete ns sql-server --wait=false
}
