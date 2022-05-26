#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

ES_INDEX=ripsaw-sysbench-results


@test "sysbench-standard" {
  CR=sysbench/sysbench.yaml
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
