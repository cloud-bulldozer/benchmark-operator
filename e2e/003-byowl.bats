#!/usr/bin/env bats

# vi: ft=bash


load helpers.bash



@test "byowl-targeted" {
  CR=byowl/byowl-targeted.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200
}

@test "byowl-not-targeted" {
  CR=byowl/byowl-not-targeted.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200
}

setup_file() {
  basic_setup
}

teardown() {
  basic_teardown
}
