#!/usr/bin/env bash

ERRORED=false
image_location=${RIPSAW_CI_IMAGE_LOCATION:-quay.io}
image_account=${RIPSAW_CI_IMAGE_ACCOUNT:-rht_perf_ci}
echo "using container image location $image_location and account $image_account"

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
  touch tests/iterate_tests
  if [[ $(echo ${1} | grep 'roles/fs-drift') ]]; then echo "test_fs_drift.sh" >> tests/iterate_tests; fi
  if [[ $(echo ${1} | grep 'roles/uperf-bench') ]]; then echo "test_uperf.sh" >> tests/iterate_tests; fi
  if [[ $(echo ${1} | grep 'roles/fio-distributed') ]]; then echo "test_fiod.sh" >> tests/iterate_tests; fi
  if [[ $(echo ${1} | grep 'roles/iperf3-bench') ]]; then echo "test_iperf3.sh" >> tests/iterate_tests; fi
  if [[ $(echo ${1} | grep 'roles/byowl') ]]; then echo "test_byowl.sh" >> tests/iterate_tests; fi
  if [[ $(echo ${1} | grep 'roles/sysbench') ]]; then echo "test_sysbench.sh" >> tests/iterate_tests; fi
  if [[ $(echo ${1} | grep 'roles/pgbench') ]]; then echo "test_pgbench.sh" >> tests/iterate_tests; fi
  if [[ $(echo ${1} | grep 'roles/ycsb-bench') ]]; then echo "test_ycsb.sh" >> tests/iterate_tests; fi
}

function wait_clean {
  kubectl delete all --all -n my-ripsaw
  for i in {1..30}; do
    if [ `kubectl get pods --namespace my-ripsaw | grep bench | wc -l` -ge 1 ]; then
      sleep 5
    else
      break
    fi
  done
}

# The argument is 'timeout in seconds'
function get_uuid () {
  sleep_time=$1
  sleep $sleep_time
  counter=0
  counter_max=6
  uuid="False"
  until [ $uuid != "False" ] ; do
    uuid=$(kubectl -n my-ripsaw get benchmarks -o jsonpath='{.items[0].status.uuid}')
    if [ -z $uuid ]; then
      sleep $sleep_time
      uuid="False"
    fi
    counter=$(( counter+1 ))
    if [ $counter -eq $counter_max ]; then
      return 1
    fi
  done
  echo ${uuid:0:8}
  return 0
}


# Two arguments are 'pod label' and 'timeout in seconds'
function get_pod () {
  counter=0
  sleep_time=5
  counter_max=$(( $2 / sleep_time ))
  pod_name="False"
  until [ $pod_name != "False" ] ; do
    sleep $sleep_time
    pod_name=$(kubectl get pods -l $1 --namespace ${3:-my-ripsaw} -o name | cut -d/ -f2)
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
    pod_count=$(kubectl get pods -n my-ripsaw -l $1 -o name | wc -l)
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
  operator_requirements
  kubectl apply -f resources/operator.yaml
  ripsaw_pod=$(get_pod 'name=benchmark-operator' 300)
  kubectl wait --for=condition=Initialized "pods/$ripsaw_pod" --namespace my-ripsaw --timeout=60s
  kubectl wait --for=condition=Ready "pods/$ripsaw_pod" --namespace my-ripsaw --timeout=300s
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
  operator-sdk build $image_location/$image_account/benchmark-operator:$tag_name --image-builder podman

  # In case we have issues uploading to quay we will retry a few times
  try_count=0
  while [ $try_count -le 2 ]
  do
    if podman push $image_location/$image_account/benchmark-operator:$tag_name
    then
      try_count=2
    elif [[ $try_count -eq 2 ]]
    then
      echo "Could not upload image to quay. Exiting"
      exit 1
    fi
    ((try_count++))
  done
  sed -i "s|          image: quay.io/benchmark-operator/benchmark-operator:master*|          image: $image_location/$image_account/benchmark-operator:$tag_name # |" resources/operator.yaml
}

function check_log(){
  for i in {1..10}; do
    if kubectl logs -f $1 --namespace my-ripsaw | grep -q $2 ; then
      break;
    else
      sleep 10
    fi
  done
}

# Takes 2 or more arguments: 'command to run', 'time to wait until true'
# Any additional arguments will be passed to kubectl -n my-ripsaw logs to provide logging if a timeout occurs
function wait_for() {
  if ! timeout -k $2 $2 $1
  then
      echo "Timeout exceeded for: "$1

      counter=3
      until [ $counter -gt $# ]
      do
        echo "Logs from "${@:$counter}
        kubectl -n my-ripsaw logs --tail=40 ${@:$counter}
        counter=$(( counter+1 ))
      done
      return 1
  fi
  return 0
}

function error {
  echo "Error caught. Dumping logs before exiting"
  echo "Benchmark operator Logs"
  kubectl -n my-ripsaw logs --tail=40 -l name=benchmark-operator -c benchmark-operator
  echo "Ansible sidecar Logs"
  kubectl -n my-ripsaw logs -l name=benchmark-operator -c ansible
  ERRORED=true
}

function wait_for_backpack() {
  echo "Waiting for backpack to complete before starting benchmark test"
  
  uuid=$1
  count=0
  max_count=60
  while [[ $count -lt $max_count ]]
  do
    if [[ `kubectl -n my-ripsaw get daemonsets backpack-$uuid` ]]
    then
      desired=`kubectl -n my-ripsaw get daemonsets backpack-$uuid | grep -v NAME | awk '{print $2}'`
      ready=`kubectl -n my-ripsaw get daemonsets backpack-$uuid | grep -v NAME | awk '{print $4}'`
      if [[ $desired -eq $ready ]]
      then
        echo "Backpack complete. Starting benchmark"
        count=$max_count
      fi
    fi
    if [[ $count -ne $max_count ]]
    then
      sleep 5
      count=$((count + 1))
    fi
  done
}
