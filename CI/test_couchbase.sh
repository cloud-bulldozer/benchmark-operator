#!/usr/bin/env bash
set -xeo pipefail

source CI/common.sh

function finish {
  echo "Cleaning up couchbase"
  kubectl delete -f CI/test_crs/valid_couchbase.yaml
  kubectl delete csv --all -n ripsaw
  kubectl delete secret 1979710-benchmark-operator-ci-pull-secret -n ripsaw
  marketplace_cleanup
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
  marketplace_setup
  kubectl apply -f /root/.1979710-benchmark-operator-ci-pull-secret.yaml -n ripsaw
  sleep 15
  kubectl apply -f CI/test_crs/valid_couchbase.yaml
  cb_operator_pod=$(get_pod 'name=couchbase-operator' 300)
  kubectl wait --for=condition=Initialized "pods/$cb_operator_pod" --namespace ripsaw --timeout=60s
  kubectl wait --for=condition=Ready "pods/$cb_operator_pod" --namespace ripsaw --timeout=300s
  cb_app_pod=$(get_pod 'app=couchbase' 600)
  kubectl wait --for=condition=Initialized "pods/$cb_app_pod" --namespace ripsaw --timeout=60s
  kubectl wait --for=condition=Ready "pods/$cb_app_pod" --namespace ripsaw --timeout=300s
  sleep 15
  check_cbc 300
}

functional_test_couchbase
