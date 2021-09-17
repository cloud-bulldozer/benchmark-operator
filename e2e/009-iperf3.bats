#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash



@test "iperf3-standard" {
  CR=iperf3/iperf3.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 900
}

setup_file() {
  basic_setup
}

teardown() {
  basic_teardown
}
