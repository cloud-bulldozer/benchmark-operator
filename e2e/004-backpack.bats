#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

indexes=(cpu_vulnerabilities-metadata cpuinfo-metadata dmidecode-metadata k8s_nodes-metadata lspci-metadata meminfo-metadata sysctl-metadata ocp_network_operator-metadata ocp_install_config-metadata ocp_kube_apiserver-metadata ocp_dns-metadata ocp_kube_controllermanager-metadata)


@test "backpack-init" {
  CR=backpack/backpack-init.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200
  check_es
}

@test "backpack-daemonset" {
  CR=backpack/backpack-daemonset.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 1200
  check_es
}

setup_file() {
  basic_setup
  kubectl apply -f ../resources/backpack_role.yaml --overwrite
}


teardown_file() {
  kubectl delete -f ../resources/backpack_role.yaml
}

teardown() {
  basic_teardown
}
