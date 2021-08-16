#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

ES_INDEX=ripsaw-uperf-results


@test "uperf-standard" {
  CR=uperf/uperf.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 600
  check_es
}

@test "uperf-resources" {
  CR=uperf/uperf_resources.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 600
  check_es
}

@test "uperf-network policy" {
  CR=uperf/uperf_networkpolicy.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 600
  check_es
}

@test "uperf-serviceip" {
  CR=uperf/uperf_serviceip.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 600
  check_es
}

@test "uperf-hostnetwork" {
  CR=uperf/uperf_hostnetwork.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 600
  check_es
}

setup_file() {
  basic_setup
}
