#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

indexes=(ripsaw-fio-results ripsaw-fio-log ripsaw-fio-analyzed-result)


@test "fio-standard" {
  CR=fio/fio.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 600
  check_es
}

@test "fio-bsrange" {
  CR=fio/fio_bsrange.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 600
  check_es
}

@test "fio-hostpath" {
  CR=fio/fio_hostpath.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f - 
  get_uuid "${CR_NAME}"
  check_benchmark 600
  check_es
}

@test "fio-ocs-cachedrop" {
  CR=fio/fio_ocs_cache_drop.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  openshift_storage_present=$(kubectl get ns | awk '/openshift-storage/' | wc -l)
  if [ $openshift_storage_present -gt 0 ]; then
    kubectl label nodes -l node-role.kubernetes.io/worker= kernel-cache-dropper=yes --overwrite
    kubectl patch OCSInitialization ocsinit -n openshift-storage --type json --patch \
      '[{ "op": "replace", "path": "/spec/enableCephTools", "value": true }]'
    drop_cache_pods=$(kubectl -n openshift-storage get pod | awk '/drop/' | awk '/unning/' | wc -l)
    if [ $drop_cache_pods -eq 0 ] ; then
      kubectl create -f ../resources/ceph_osd_cache_drop/rook_ceph_drop_cache_pod.yaml
      kubectl wait --for=condition=Initialized pods/rook-ceph-osd-cache-drop -n openshift-storage --timeout=100s
    fi
    sleep 5
    envsubst < ${CR} | kubectl apply -f - 
    get_uuid "${CR_NAME}"
    check_benchmark 600
    check_es
  fi
}

setup_file() {
  basic_setup
}

teardown() {
  basic_teardown
}
