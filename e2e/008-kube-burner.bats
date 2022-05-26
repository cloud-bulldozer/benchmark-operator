#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

ES_INDEX=ripsaw-kube-burner


@test "kube-burner-cluster-density" {
  CR=kube-burner/cluster-density.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200
  check_es
}

@test "kube-burner-node-density" {
  CR=kube-burner/node-density.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200
}

@test "kube-burner-node-density-heavy" {
  CR=kube-burner/node-density-heavy.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200
}

@test "kube-burner-node-density-cni" {
  CR=kube-burner/node-density-cni.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200
}

@test "kube-burner-node-density-cni-networkpolicy" {
  CR=kube-burner/node-density-cni-networkpolicy.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200
}

@test "kube-burner-max-services" {
  CR=kube-burner/max-services.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200
}

@test "kube-burner-max-namespaces" {
  CR=kube-burner/max-namespaces.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200
}

@test "kube-burner-concurrent-builds" {
  CR=kube-burner/concurrent-builds.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200
}

@test "kube-burner-configmap" {
  CR=kube-burner/configmap.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200
  check_es
}

setup_file() {
  basic_setup
  kubectl apply -f ../resources/kube-burner-role.yml
  kubectl apply -f kube-burner/configmap-cfg.yaml
}

teardown_file() {
  kubectl delete -f ../resources/kube-burner-role.yml
  kubectl delete -f kube-burner/configmap-cfg.yaml
}

teardown() {
  basic_teardown
  kubectl delete ns -l kube-burner-uuid=${uuid} --ignore-not-found
}
