#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

ES_INDEX=log-generator-results


@test "log_generator-standard" {
  CR=log_generator/log_generator.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200
  check_es
}

setup_file() {
  basic_setup
}

teardown() {
  basic_teardown
}

