#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up sysbench"
  wait_clean
}

trap error ERR
trap finish EXIT

function functional_test_sysbench {
  cr=tests/test_crs/valid_sysbench.yaml
  delete_benchmark $cr
  kubectl apply -f $cr
  benchmark_name=$(get_benchmark_name $cr)
  long_uuid=$(get_uuid $benchmark_name)
  uuid=${long_uuid:0:8}

  sysbench_pod=$(get_pod "app=sysbench-$uuid" 300)
  check_benchmark_for_desired_state $benchmark_name Complete 800s
  # sleep isn't needed as the sysbench is kind: job so once it's complete we can access logs
  # ensuring the run has actually happened
  kubectl logs "$sysbench_pod" --namespace benchmark-operator | grep "execution time"
  echo "Sysbench test: Success"
  delete_benchmark $cr
}

figlet $(basename $0)
functional_test_sysbench
