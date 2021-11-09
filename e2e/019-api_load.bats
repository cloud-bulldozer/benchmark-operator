#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash


@test "api-load-standard" {
  CR=api_load/api_load.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 120
}

setup_file() {
  basic_setup
}

teardown() {
  basic_teardown
}
