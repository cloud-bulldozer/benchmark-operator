#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  echo "Cleaning up couchbase"
  kubectl delete -f tests/test_crs/valid_ycsb-couchbase.yaml
  kubectl delete deployment couchbase-operator
  delete_operator
}

# Two arguments are 'pod label' and 'timeout in seconds'
function get_pod () {
  counter=0
  sleep_time=5
  counter_max=$(( $2 / sleep_time ))
  pod_name="False"
  until [ $pod_name != "False" ] ; do
    sleep $sleep_time
    pod_name=$(kubectl get pods -l $1 --namespace ripsaw -o name | cut -d/ -f2)
    if [ -z $pod_name ]; then
      pod_name="False"
    fi
    counter=$(( counter+1 ))
    if [ $counter -eq $counter_max ]; then
      return 1
    fi
  done
  echo $pod_name
  return 0
}

# Argument is 'timeout in seconds'
function check_cbc () {
  counter=0
  sleep_time=5
  counter_max=$(( $1 / sleep_time ))
  cbc_status="False"
  until [ $cbc_status == "True" ] ; do
    sleep $sleep_time
    cbc_status=$(kubectl get cbc --namespace ripsaw -o jsonpath='{.items[*].status.conditions.Balanced.status}' || echo False)
    if [ -z $cbc_status ]; then
      cbc_status="False"
    fi
    counter=$(( counter+1 ))
    if [ $counter -eq $counter_max ]; then
      echo "Timeout checking CBC"
      return 1
    fi
  done
  echo "CBC is good"
  return 0
}


trap finish EXIT


# Note we don't test persistent storage here
function functional_test_couchbase {
  apply_operator
  sleep 15
  kubectl apply -f /root/.1979710-benchmark-operator-ci-pull-secret.yaml
  kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "1979710-benchmark-operator-ci-pull-secret"}]}'
  kubectl apply -f tests/test_crs/valid_ycsb-couchbase.yaml
  cb_operator_pod=$(get_pod 'name=couchbase-operator' 300)
  kubectl wait --for=condition=Initialized "pods/$cb_operator_pod" --namespace ripsaw --timeout=60s
  kubectl wait --for=condition=Ready "pods/$cb_operator_pod" --namespace ripsaw --timeout=300s
  cb_app_pod=$(get_pod 'app=couchbase' 600)
  kubectl wait --for=condition=Initialized "pods/$cb_app_pod" --namespace ripsaw --timeout=60s
  kubectl wait --for=condition=Ready "pods/$cb_app_pod" --namespace ripsaw --timeout=300s
  sleep 15
  check_cbc 300
  ycsb_load_pod=$(get_pod 'name=ycsb-load' 120)
  kubectl wait --for=condition=Initialized "pods/$ycsb_load_pod" --namespace ripsaw --timeout=60s
  kubectl wait --for=condition=Ready "pods/$ycsb_load_pod" --namespace ripsaw --timeout=120s
  ycsb_run_pod=$(get_pod 'name=ycsb-run' 120)
  kubectl wait --for=condition=Initialized "pods/$ycsb_run_pod" --namespace ripsaw --timeout=60s
  kubectl wait --for=condition=Ready "pods/$ycsb_run_pod" --namespace ripsaw --timeout=120s
}

functional_test_couchbase
