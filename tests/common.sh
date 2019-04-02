#!/usr/bin/env bash

function apply_operator {
  kubectl apply -f resources/operator.yaml
}

function delete_operator {
  kubectl delete -f resources/operator.yaml
}

function operator_requirements {
  kubectl apply -f deploy
  kubectl apply -f resources/crds/benchmark_v1alpha1_benchmark_crd.yaml
}

function create_operator {
  operator_requirements
  apply_operator
}

function cleanup_resources {
  echo "Exiting after cleanup of resources"
  kubectl delete -f resources/crds/benchmark_v1alpha1_benchmark_crd.yaml
  kubectl delete -f deploy
}

function cleanup_operator_resources {
  delete_operator
  cleanup_resources
}

function update_operator_image {
  operator-sdk build quay.io/rht_perf_ci/benchmark-operator
  docker push quay.io/rht_perf_ci/benchmark-operator
  sed -i 's|          image: *|          image: quay.io/rht_perf_ci/benchmark-operator:latest # |' resources/operator.yaml
}

function wait_clean {
  for i in {1..30}; do
    if [ `kubectl get pods | grep bench | wc -l` -ge 1 ]; then
      sleep 5
    else
      break
    fi
  done
}

function check_pods() {
  for i in {1..10}; do
    if [ `kubectl get pods | grep bench | wc -l` -gt $1 ]; then
      break
    else
      sleep 10
    fi
  done
}

function check_log(){
  for i in {1..10}; do
    if kubectl logs -f $1 | grep -q $2 ; then
      break;
    else
      sleep 10
    fi
  done
}
