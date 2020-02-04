#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up smallfile"
  wait_clean
}


trap error ERR
trap finish EXIT

function functional_test_smallfile {
  apply_operator
  test_name=$1
  cr=$2
  echo "Performing: ${test_name}"
  kubectl apply -f ${cr}
  uuid=$(get_uuid 20)
  wait_for_backpack $uuid  
  count=0
  while [[ $count -lt 24 ]]; do
    if [[ `kubectl get pods -l app=smallfile-benchmark-$uuid --namespace my-ripsaw -o name | cut -d/ -f2 | grep client` ]]; then
      smallfile_pod=$(kubectl get pods -l app=smallfile-benchmark-$uuid --namespace my-ripsaw -o name | cut -d/ -f2 | grep client)
      count=30
    fi
    if [[ $count -ne 30 ]]; then
      sleep 5
      count=$((count + 1))
    fi
  done
  echo "smallfile_pod ${smallfile_pod}"
  wait_for "kubectl wait --for=condition=Initialized -l app=smallfile-benchmark-$uuid pods --namespace my-ripsaw --timeout=200s" "200s"
  wait_for "kubectl wait --for=condition=complete -l app=smallfile-benchmark-$uuid jobs --namespace my-ripsaw --timeout=100s" "100s"
  # ensuring the run has actually happened
  for pod in ${smallfile_pod}; do
    kubectl logs ${pod} --namespace my-ripsaw | grep "RUN STATUS"
  done
  echo "${test_name} test: Success"
}

figlet $(basename $0)
functional_test_smallfile "smallfile" tests/test_crs/valid_smallfile.yaml
wait_clean
functional_test_smallfile "smallfile hostpath" tests/test_crs/valid_smallfile_hostpath.yaml
