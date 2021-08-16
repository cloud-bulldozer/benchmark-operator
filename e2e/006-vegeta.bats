#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

ES_INDEX=ripsaw-vegeta-results


@test "vegeta-standard" {
  CR=vegeta/vegeta.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 600
  check_es
}

@test "vegeta-hostpath" {
  CR=vegeta/vegeta_hostnetwork.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 600
  check_es
}

setup_file() {
  basic_setup
}
