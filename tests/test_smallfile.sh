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
  smallfile_pod=$(get_pod "app=smallfile-benchmark-$uuid" 300)
  echo "smallfile_pod ${smallfile_pod}"
  check_benchmark_for_desired_state $benchmark_name Complete 500s

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
  delete_benchmark $cr
}

figlet $(basename $0)
functional_test_smallfile "smallfile" tests/test_crs/valid_smallfile.yaml
functional_test_smallfile "smallfile hostpath" tests/test_crs/valid_smallfile_hostpath.yaml
