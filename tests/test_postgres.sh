#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  echo "Cleaning up postgres"
  kubectl delete -f tests/test_crs/valid_postgres.yaml
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
function check_postgresql () {
  counter=0
  sleep_time=5
  counter_max=$(( $1 / sleep_time ))
  pg_status="False"
  until [ $pg_status == "Running" ] ; do
    sleep $sleep_time
    pg_status=$(kubectl get postgresql --namespace ripsaw -o jsonpath='{.items[*].status.PostgresClusterStatus}' || echo False)
    if [ -z $pg_status ]; then
      pg_status="False"
    fi
    if [ $pg_status == "CreateFailed" ]; then
      echo "Postgresql creation failed"
      return 1
    fi
    counter=$(( counter+1 ))
    if [ $counter -eq $counter_max ]; then
      echo "Timeout checking Postgresql"
      return 1
    fi
  done
  echo "Postgresql is good"
  return 0
}

trap finish EXIT


# Note we don't test persistent storage here
function functional_test_postgres {
  apply_operator
  ripsaw_pod=$(get_pod 'name=benchmark-operator' 300)
  kubectl wait --for=condition=Initialized "pods/$ripsaw_pod" --namespace ripsaw --timeout=60s
  kubectl wait --for=condition=Ready "pods/$ripsaw_pod" --namespace ripsaw --timeout=300s
  # first teardown any previous resources from this test
  kubectl apply -f tests/test_crs/teardown_postgres.yaml
  # deploy the test CR
  kubectl apply -f tests/test_crs/valid_postgres.yaml
  pg_operator_pod=$(get_pod 'name=postgres-operator' 300)
  kubectl wait --for=condition=Initialized "pods/$pg_operator_pod" --namespace ripsaw --timeout=60s
  kubectl wait --for=condition=Ready "pods/$pg_operator_pod" --namespace ripsaw --timeout=300s
  pg_app_pod=$(get_pod 'spilo-role=master' 1200)
  kubectl wait --for=condition=Initialized "pods/$pg_app_pod" --namespace ripsaw --timeout=60s
  kubectl wait --for=condition=Ready "pods/$pg_app_pod" --namespace ripsaw --timeout=300s
  check_postgresql 300
}

functional_test_postgres
