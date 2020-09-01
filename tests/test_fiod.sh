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
  apply_operator
  test_name=$1
  cr=$2
  echo "Performing: ${test_name}"
  kubectl apply -f ${cr}
  long_uuid=$(get_uuid 20)
  uuid=${long_uuid:0:8}

  pod_count "app=fio-benchmark-$uuid" 2 300  
  wait_for "kubectl -n my-ripsaw wait --for=condition=Initialized -l app=fio-benchmark-$uuid pods --timeout=300s" "300s"
  fio_pod=$(get_pod "app=fiod-client-$uuid" 300)
  wait_for "kubectl wait --for=condition=Initialized pods/$fio_pod -n my-ripsaw --timeout=500s" "500s" $fio_pod
  wait_for "kubectl wait --for=condition=complete -l app=fiod-client-$uuid jobs -n my-ripsaw --timeout=500s" "500s" $fio_pod

  indexes="ripsaw-fio-results ripsaw-fio-log ripsaw-fio-analyzed-result"
  if check_es "${long_uuid}" "${indexes}"
  then
    echo "${test_name} test: Success"
  else
    echo "Failed to find data for ${test_name} in ES"
    kubectl logs "$fio_pod" -n my-ripsaw
    exit 1
  fi
}

figlet $(basename $0)
nodelist="$(kubectl get nodes | awk '/Ready/{print $1}')"
for n in $nodelist ; do
    kubectl label node $n kernel-cache-dropper=yes
done
functional_test_fio "Fio distributed" tests/test_crs/valid_fiod.yaml
functional_test_fio "Fio distributed - bsrange" tests/test_crs/valid_fiod_bsrange.yaml
functional_test_fio "Fio hostpath distributed" tests/test_crs/valid_fiod_hostpath.yaml
