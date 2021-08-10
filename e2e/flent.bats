#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

export NAMESPACE=benchmark-operator
ES_INDEX=ripsaw-flent-results


@test "flent-standard" {
  CR=flent/flent.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark 300 || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
}


@test "flent-resources" {
  CR=flent/flent_resources.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark 300 || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
}

setup_file() {
  basic_setup
}

teardown_file(){
  basic_teardown
}
