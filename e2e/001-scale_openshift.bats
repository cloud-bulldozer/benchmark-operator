#!/usr/bin/env bats

# vi: ft=bash


load helpers.bash

ES_INDEX=openshift-cluster-timings


@test "scale_openshift-up" {
  CR=scale_openshift/scale_up.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200
  # Make node no schedulable as soon as benchmark finishes
  kubectl cordon $(kubectl get node --sort-by='{.metadata.creationTimestamp}' -o name | tail -1)
  # Annotate machine to ensure it's the one deleted in the scale_openshift-down test
  # Reference: https://github.com/openshift/machine-api-operator/blob/master/FAQ.md#what-decides-which-machines-to-destroy-when-a-machineset-is-scaled-down
  kubectl -n openshift-machine-api annotate $(kubectl get machine -n openshift-machine-api --sort-by='{.metadata.creationTimestamp}' -o name | tail -1) machine.openshift.io/cluster-api-delete-machine=true --overwrite
  check_es
}

@test "scale_openshift-down" {
  CR=scale_openshift/scale_down.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200 || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
}

setup_file() {
  # Prevent running scale down/up simultaneously
  export BATS_NO_PARALLELIZE_WITHIN_FILE=true
  kubectl_exec apply -f ../resources/scale_role.yaml
  basic_setup
}

teardown_file() {
  kubectl_exec delete -f ../resources/scale_role.yaml
}

teardown() {
  basic_teardown
}
