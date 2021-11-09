#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

indexes=(ripsaw-smallfile-results ripsaw-smallfile-rsptimes)


@test "smallfile-standard" {
  CR=smallfile/smallfile.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 900
  check_es
}

@test "smallfile-hostpath" {
  CR=smallfile/smallfile_hostpath.yaml
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
