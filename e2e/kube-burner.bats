#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

export NAMESPACE=benchmark-operator
ES_INDEX=ripsaw-kube-burner


@test "kube-burner-cluster-density" {
  CR=kube-burner/cluster-density.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark 480 || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
  kubectl delete ns -l kube-burner-uuid=${uuid}
}

@test "kube-burner-node-density" {
  CR=kube-burner/node-density.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark 480 || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
  kubectl delete ns -l kube-burner-uuid=${uuid}
}

@test "kube-burner-node-density-heavy" {
  CR=kube-burner/node-density-heavy.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark 480 || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
  kubectl delete ns -l kube-burner-uuid=${uuid}
}

@test "kube-burner-max-services" {
  CR=kube-burner/max-services.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark 480 || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
  kubectl delete ns -l kube-burner-uuid=${uuid}
}

@test "kube-burner-max-namespaces" {
  CR=kube-burner/max-namespaces.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark 480 || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
  kubectl delete ns -l kube-burner-uuid=${uuid}
}

@test "kube-burner-concurrent-builds" {
  CR=kube-burner/concurrent-builds.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark 480 || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
  kubectl delete ns -l kube-burner-uuid=${uuid}
}

setup_file() {
  basic_setup
  kubectl apply -f ../resources/kube-burner-role.yml
}

teardown_file(){
  basic_teardown
}
