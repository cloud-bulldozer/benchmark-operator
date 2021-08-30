#!/usr/bin/env bats

# vi: ft=bash


load helpers.bash



@test "byowl" {
  CR=byowl/byowl.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 600
}

setup_file() {
  basic_setup
}

teardown() {
  basic_teardown
}
