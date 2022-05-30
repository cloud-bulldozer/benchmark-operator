#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

indexes=(ripsaw-fs-drift-results ripsaw-fs-drift-rsptimes ripsaw-fs-drift-rates-over-time)


@test "fs-drift-standard" {
  CR=fs-drift/fs-drift.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200
  check_es
}


@test "fs-drift-hostpath" {
  CR=fs-drift/fs-drift_hostpath.yaml
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
