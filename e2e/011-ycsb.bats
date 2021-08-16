#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

indexes=(ripsaw-ycsb-summary ripsaw-ycsb-results)


@test "ycsb-mongo" {
  CR=ycsb/ycsb-mongo.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 600
  check_es
}

setup() {
  kubectl_exec apply -f ycsb/mongo.yaml
}

setup_file() {
  basic_setup
}

teardown_file() {
  kubectl_exec delete -f ycsb/mongo.yaml
}
