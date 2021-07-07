#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up fio"
  wait_clean
}

trap error ERR
trap finish EXIT

function functional_test_fio {
  wait_clean
  test_name=$1
  cr=$2
  benchmark_name=$(get_benchmark_name $cr)
  delete_benchmark $cr
  echo "Performing: ${test_name}"
  token=$(oc -n openshift-monitoring sa get-token prometheus-k8s)
  sed -e "s/PROMETHEUS_TOKEN/${token}/g" ${cr} | kubectl apply -f -
  long_uuid=$(get_uuid $benchmark_name)
  uuid=${long_uuid:0:8}

  pod_count "app=fio-benchmark-$uuid" 2 300  
  fio_pod=$(get_pod "app=fiod-client-$uuid" 300)
  check_benchmark_for_desired_state $benchmark_name Complete 1200s
  kubectl -n benchmark-operator logs $fio_pod > /tmp/$fio_pod.log




  indexes="ripsaw-fio-results ripsaw-fio-log ripsaw-fio-analyzed-result"
  if check_es "${long_uuid}" "${indexes}"
  then
    echo "${test_name} test: Success"
  else
    echo "Failed to find data for ${test_name} in ES"
    kubectl logs "$fio_pod" -n benchmark-operator
    exit 1
  fi
  delete_benchmark $cr
}

figlet $(basename $0)
kubectl label nodes -l node-role.kubernetes.io/worker= kernel-cache-dropper=yes --overwrite
functional_test_fio "Fio distributed" tests/test_crs/valid_fiod.yaml
openshift_storage_present=$(oc get namespace | awk '/openshift-storage/' | wc -l)
if [ $openshift_storage_present -gt 0 ] ; then
   oc patch OCSInitialization ocsinit -n openshift-storage --type json --patch \
     '[{ "op": "replace", "path": "/spec/enableCephTools", "value": true }]'
   drop_cache_pods=$(oc -n openshift-storage get pod | awk '/drop/' | awk '/unning/' | wc -l)
   if [ $drop_cache_pods -eq 0 ] ; then
     oc create -f roles/ceph_osd_cache_drop/rook_ceph_drop_cache_pod.yaml
     kubectl wait --for=condition=Initialized pods/rook-ceph-osd-cache-drop -n openshift-storage --timeout=100s
   fi
   sleep 5
   functional_test_fio "Fio cache drop" tests/test_crs/valid_fiod_ocs_cache_drop.yaml
fi
functional_test_fio "Fio distributed - bsrange" tests/test_crs/valid_fiod_bsrange.yaml
functional_test_fio "Fio hostpath distributed" tests/test_crs/valid_fiod_hostpath.yaml
