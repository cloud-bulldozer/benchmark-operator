#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

ES_INDEX=ripsaw-uperf-results


@test "uperf-hostnetwork-nodeport" {
  # Merging nodeport and hostnetwork test to avoid port binding conflicts
  for CR in uperf/uperf_hostnetwork.yaml uperf/uperf_serviceip_nodeport.yaml; do
    CR_NAME=$(get_benchmark_name ${CR})
    envsubst < ${CR} | kubectl apply -f -
    get_uuid "${CR_NAME}"
    check_benchmark 1200
    check_es
	kubectl_exec delete benchmark ${CR_NAME} --ignore-not-found
  done
}

@test "uperf-standard" {
  CR=uperf/uperf.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200
  check_es
}

@test "uperf-resources" {
  CR=uperf/uperf_resources.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200
  check_es
}

@test "uperf-network policy" {
  CR=uperf/uperf_networkpolicy.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200
  check_es
}

@test "uperf-serviceip" {
  CR=uperf/uperf_serviceip.yaml
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
