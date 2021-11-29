#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

indexes=(ripsaw-fs_drift-results ripsaw-fs_drift-rsptimes ripsaw-fs_drift-rates-over-time)


@test "fs_drift-standard" {
  CR=fs_drift/fs_drift.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 900
  check_es
}


@test "fs_drift-hostpath" {
  CR=fs_drift/fs_drift_hostpath.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 900
  check_es
}

setup_file() {
  basic_setup
}

teardown() {
  basic_teardown
}
