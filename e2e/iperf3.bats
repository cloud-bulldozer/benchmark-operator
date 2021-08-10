#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

export NAMESPACE=benchmark-operator


@test "iperf3-standard" {
  CR=iperf3/iperf3.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark 300 || die "Timeout waiting for benchmark/${CR_NAME} to complete"
}

setup_file() {
  basic_setup
}

teardown_file(){
  basic_teardown
}
