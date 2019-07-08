#!/usr/bin/env bash

function check_full_trigger {
python - <<END
import os
with open('tests/full_test_file_trigger', 'r') as file:
    a = file.read()
a = filter(None,a.split('\n'))
with open('tests/git_diff', 'r') as file:
    b = file.read()
b = filter(None,b.split('\n'))
print(any((x in a for x in b)))
END
}

function populate_test_list {
  if 'roles/uperf-bench' in $1; then echo "test_uperf.sh" >> tests/iterate_tests; fi
  if 'roles/fio-distributed' in $1; then echo "test_fiod.sh" >> tests/iterate_tests; fi
  if 'roles/iperf3-bench' in $1; then echo "test_iperf3.sh" >> tests/iterate_tests; fi
  if 'roles/byowl' in $1; then echo "test_byowl.sh" >> tests/iterate_tests; fi
  if 'roles/sysbench' in $1; then echo "test_sysbench.sh" >> tests/iterate_tests; fi
  if 'roles/pgbench' in $1; then echo "test_pgbench.sh" >> tests/iterate_tests; fi
}

function wait_clean {
  kubectl delete --all jobs --namespace ripsaw
  kubectl delete --all deployments --namespace ripsaw
  kubectl delete --all pods --namespace ripsaw
  for i in {1..30}; do
    if [ `kubectl get pods --namespace ripsaw | grep bench | wc -l` -ge 1 ]; then
      sleep 5
    else
      break
    fi
  done
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

# Three arguments are 'pod label', 'expected count', and 'timeout in seconds'
function pod_count () {
  counter=0
  sleep_time=5
  counter_max=$(( $3 / sleep_time ))
  pod_count=0
  export $1
  until [ $pod_count == $2 ] ; do
    sleep $sleep_time
    pod_count=$(kubectl get pods -n ripsaw -l $1 -o name | wc -l)
    if [ -z $pod_count ]; then
      pod_count=0
    fi
    counter=$(( counter+1 ))
    if [ $counter -eq $counter_max ]; then
      return 1
    fi
  done
  echo $pod_count
  return 0
}

function apply_operator {
  kubectl apply -f resources/operator.yaml
  ripsaw_pod=$(get_pod 'name=benchmark-operator' 300)
  kubectl wait --for=condition=Initialized "pods/$ripsaw_pod" --namespace ripsaw --timeout=60s
  kubectl wait --for=condition=Ready "pods/$ripsaw_pod" --namespace ripsaw --timeout=300s
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

function check_log(){
  for i in {1..10}; do
    if kubectl logs -f $1 --namespace ripsaw | grep -q $2 ; then
      break;
    else
      sleep 10
    fi
  done
}
