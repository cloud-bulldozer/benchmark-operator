#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

indexes=(ripsaw-pgbench-summary ripsaw-pgbench-raw)


@test "pgbench-standard" {
  CR=pgbench/pgbench.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 600
  check_es
}


setup_file() {
  basic_setup
  kubectl_exec apply -f pgbench/postgres.yaml
  kubectl_exec rollout status deploy/postgres --timeout=60s
  export POSTGRES_IP=$(kubectl_exec get pod -l app=postgres -o jsonpath="{.items[*].status.podIP}")
}

teardown_file() {
  kubectl_exec delete -f pgbench/postgres.yaml
}
