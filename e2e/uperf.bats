#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

export NAMESPACE=benchmark-operator
ES_INDEX=ripsaw-uperf-results


@test "uperf-standard" {
  CR=uperf/uperf.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark 600 || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
}

@test "uperf-resources" {
  CR=uperf/uperf_resources.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark 300 || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
}

@test "uperf-network policy" {
  CR=uperf/uperf_networkpolicy.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark 300 || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
}

@test "uperf-serviceip" {
  CR=uperf/uperf_serviceip.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark 300 || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
}

@test "uperf-hostnetwork" {
  CR=uperf/uperf_hostnetwork.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark 300 || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
}

setup_file() {
  basic_setup
}

teardown_file(){
  basic_teardown
}
