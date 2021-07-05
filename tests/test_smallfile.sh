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
  test_name=$1
  cr=$2
  delete_benchmark $cr
  benchmark_name=$(get_benchmark_name $cr)
  echo "Performing: ${test_name}"
  token=$(oc -n openshift-monitoring sa get-token prometheus-k8s)
  sed -e "s/PROMETHEUS_TOKEN/${token}/g" ${cr} | kubectl apply -f -
  long_uuid=$(get_uuid $benchmark_name)
  uuid=${long_uuid:0:8}

  count=0
  while [[ $count -lt 24 ]]; do
    if [[ `kubectl get pods -l app=smallfile-benchmark-$uuid --namespace benchmark-operator -o name | cut -d/ -f2 | grep client` ]]; then
      smallfile_pod=$(kubectl get pods -l app=smallfile-benchmark-$uuid --namespace benchmark-operator -o name | cut -d/ -f2 | grep client)
      count=30
    fi
    if [[ $count -ne 30 ]]; then
      sleep 5
      count=$((count + 1))
    fi
  done
  echo "smallfile_pod ${smallfile_pod}"
  wait_for "kubectl wait --for=condition=Initialized -l app=smallfile-benchmark-$uuid pods --namespace benchmark-operator --timeout=500s" "500s"
  wait_for "kubectl wait --for=condition=complete -l app=smallfile-benchmark-$uuid jobs --namespace benchmark-operator --timeout=100s" "100s"

  indexes="ripsaw-smallfile-results ripsaw-smallfile-rsptimes"
  if check_es "${long_uuid}" "${indexes}"
  then
    echo "${test_name} test: Success"
  else
    echo "Failed to find data for ${test_name} in ES"
    for pod in ${smallfile_pod}; do
      kubectl logs ${pod} --namespace benchmark-operator | grep "RUN STATUS"
    done
    exit 1
  fi
}

figlet $(basename $0)
functional_test_smallfile "smallfile" tests/test_crs/valid_smallfile.yaml
functional_test_smallfile "smallfile hostpath" tests/test_crs/valid_smallfile_hostpath.yaml
