#!/usr/bin/env bash

function wait_clean {
  for i in {1..30}; do
    if [ `kubectl get pods --namespace ripsaw | grep bench | wc -l` -ge 1 ]; then
      sleep 5
    else
      break
    fi
  done
}

function apply_operator {
  kubectl apply -f resources/operator.yaml
}

function delete_operator {
  kubectl delete -f resources/operator.yaml
}

function marketplace_setup {
  kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/01_namespace.yaml
  kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/02_catalogsourceconfig.crd.yaml
  kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/03_operatorsource.crd.yaml
  kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/04_service_account.yaml
  kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/05_role.yaml
  kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/06_role_binding.yaml
  kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/07_upstream_operatorsource.cr.yaml
  kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/08_operator.yaml
}

function marketplace_cleanup {
  kubectl delete -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/07_upstream_operatorsource.cr.yaml
  kubectl delete -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/08_operator.yaml
  kubectl delete -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/06_role_binding.yaml
  kubectl delete -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/05_role.yaml
  kubectl delete -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/04_service_account.yaml
  kubectl delete -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/03_operatorsource.crd.yaml
  kubectl delete -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/02_catalogsourceconfig.crd.yaml
  kubectl delete -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/01_namespace.yaml
}

function operator_requirements {
  marketplace_setup
  kubectl apply -f deploy
  kubectl apply -f resources/crds/ripsaw_v1alpha1_ripsaw_crd.yaml
}

function create_operator {
  operator_requirements
  apply_operator
}

function cleanup_resources {
  echo "Exiting after cleanup of resources"
  kubectl delete -f resources/crds/ripsaw_v1alpha1_ripsaw_crd.yaml
  kubectl delete -f deploy
  marketplace_cleanup
}

function cleanup_operator_resources {
  delete_operator
  cleanup_resources
  wait_clean
}

function update_operator_image {
  tag_name="${NODE_NAME:-master}"
  operator-sdk build quay.io/rht_perf_ci/benchmark-operator:$tag_name
  docker push quay.io/rht_perf_ci/benchmark-operator:$tag_name
  sed -i "s|          image: quay.io/benchmark-operator/benchmark-operator:master*|          image: quay.io/rht_perf_ci/benchmark-operator:$tag_name # |" resources/operator.yaml
}


function check_pods() {
  for i in {1..10}; do
    if [ `kubectl get pods --namespace ripsaw | grep bench | wc -l` -gt $1 ]; then
      break
    else
      sleep 10
    fi
  done
}

function check_log(){
  for i in {1..10}; do
    if kubectl logs -f $1 --namespace ripsaw | grep -q $2 ; then
      break;
    else
      sleep 10
    fi
  done
}
