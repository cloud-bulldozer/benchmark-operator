#!/usr/bin/env bash

ERRORED=false
image_location=${RIPSAW_CI_IMAGE_LOCATION:-quay.io}
image_account=${RIPSAW_CI_IMAGE_ACCOUNT:-rht_perf_ci}
es_url=${ES_SERVER:-http://foo.esserver.com:9200}
echo "using container image location $image_location and account $image_account"

function populate_test_list {
  rm -f tests/iterate_tests

  if [ -n $1 ]; then 
    echo $1 >> tests/iterate_tests
  else

    for item in $@
    do
      # Check for changes in roles
      if [[ $(echo ${item} | grep 'roles/fs-drift') ]]; then echo "test_fs_drift.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'roles/uperf') ]]; then echo "test_uperf.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'roles/fio_distributed') ]]; then echo "test_fiod.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'roles/iperf3') ]]; then echo "test_iperf3.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'roles/byowl') ]]; then echo "test_byowl.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'roles/sysbench') ]]; then echo "test_sysbench.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'roles/pgbench') ]]; then echo "test_pgbench.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'roles/ycsb') ]]; then echo "test_ycsb.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'roles/backpack') ]]; then echo "test_backpack.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'roles/hammerdb') ]]; then echo "test_hammerdb.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'roles/smallfile') ]]; then echo "test_smallfile.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'roles/vegeta') ]]; then echo "test_vegeta.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'roles/stressng') ]]; then echo "test_stressng.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'roles/scale_openshift') ]]; then echo "test_scale_openshift.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'roles/kube-burner') ]]; then echo "test_kubeburner.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'roles/flent') ]]; then echo "test_flent.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'roles/log_generator') ]]; then echo "test_log_generator.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'roles/image_pull') ]]; then echo "test_image_pull.sh" >> tests/iterate_tests; fi


      # Check for changes in cr files
      if [[ $(echo ${item} | grep 'valid_backpack*') ]]; then echo "test_backpack.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'valid_byowl*') ]]; then echo "test_byowl.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'valid_fiod*') ]]; then echo "test_fiod.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'valid_fs_drift*') ]]; then echo "test_fs_drift.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'valid_hammerdb*') ]]; then echo "test_hammerdb.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'valid_iperf3*') ]]; then echo "test_iperf3.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'valid_pgbench*') ]]; then echo "test_pgbench.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'valid_smallfile*') ]]; then echo "test_smallfile.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'valid_sysbench*') ]]; then echo "test_sysbench.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'valid_uperf*') ]]; then echo "test_uperf.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'valid_ycsb*') ]]; then echo "test_ycsb.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'valid_vegeta*') ]]; then echo "test_vegeta.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'valid_stressng*') ]]; then echo "test_stressng.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'valid_scale*') ]]; then echo "test_scale_openshift.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'valid_kube-burner*') ]]; then echo "test_kubeburner.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'valid_flent*') ]]; then echo "test_flent.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'valid_log_generator*') ]]; then echo "test_log_generator.sh" >> tests/iterate_tests; fi
      if [[ $(echo ${item} | grep 'valid_image_pull*') ]]; then echo "test_image_pull.sh" >> tests/iterate_tests; fi


      # Check for changes in test scripts
      test_check=`echo $item | awk -F / '{print $2}'`

      if [[ $(echo ${test_check} | grep 'test_.*.sh') ]]; then echo ${test_check} >> tests/iterate_tests; fi
    done
  fi
}

function delete_benchmark {
  kubectl delete -f $1 --ignore-not-found=true
}

function wait_clean {
  if [[ `kubectl get benchmarks.ripsaw.cloudbulldozer.io --all-namespaces` ]]
  then
    echo "skipping cleanup"
  fi
}

# The argument is 'timeout in seconds'
function get_uuid () {
  sleep_time=$1
  sleep $sleep_time
  counter=0
  counter_max=6
  uuid="False"
  until [ $uuid != "False" ] ; do
    uuid=$(kubectl -n benchmark-operator get benchmarks -o jsonpath='{.items[0].status.uuid}')
    if [ -z $uuid ]; then
      sleep $sleep_time
      uuid="False"
    fi
    counter=$(( counter+1 ))
    if [ $counter -eq $counter_max ]; then
      return 1
    fi
  done
  echo $uuid
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
    pod_name=$(kubectl get pods -l $1 --namespace ${3:-benchmark-operator} -o name | cut -d/ -f2)
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
    pod_count=$(kubectl get pods -n benchmark-operator -l $1 -o name | wc -l)
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
  tag_name="${NODE_NAME:-master}"
  make podman-build podman-push deploy IMG=$image_location/$image_account/benchmark-operator:$tag_name
  kubectl wait --for=condition=available "deployment/benchmark-controller-manager" -n benchmark-operator --timeout=300s
}

function delete_operator {
  make undeploy
}


function backpack_requirements {
  kubectl apply -f resources/backpack_role.yaml
  if [[ `command -v oc` ]]
  then
    if [[ `oc get securitycontextconstraints.security.openshift.io` ]]
    then
      oc adm policy -n benchmark-operator add-scc-to-user privileged -z ripsaw-controller-manager
      oc adm policy -n benchmark-operator add-scc-to-user privileged -z backpack-view
    fi
  fi
}


function cleanup_operator_resources {
  delete_operator
  wait_clean
}

function check_log(){
  for i in {1..10}; do
    if kubectl logs -f $1 --namespace benchmark-operator | grep -q $2 ; then
      break;
    else
      sleep 10
    fi
  done
}

# Takes 2 or more arguments: 'command to run', 'time to wait until true'
# Any additional arguments will be passed to kubectl -n benchmark-operator logs to provide logging if a timeout occurs
function wait_for() {
  if ! timeout -k $2 $2 $1
  then
      echo "Timeout exceeded for: "$1

      counter=3
      until [ $counter -gt $# ]
      do
        echo "Logs from "${@:$counter}
        kubectl -n benchmark-operator logs --tail=40 ${@:$counter}
        counter=$(( counter+1 ))
      done
      return 1
  fi
  return 0
}

function error {
  if [[ $ERRORED == "true" ]]
  then
    exit
  fi

  ERRORED=true

  echo "Error caught. Dumping logs before exiting"
  echo "Benchmark operator Logs"
  kubectl -n benchmark-operator logs --tail=200 -l control-plane=controller-manager -c manager
}

function wait_for_backpack() {
  echo "Waiting for backpack to complete before starting benchmark test"

  uuid=$1
  count=0
  max_count=60
  while [[ $count -lt $max_count ]]
  do
    if [[ `kubectl -n benchmark-operator get daemonsets backpack-$uuid` ]]
    then
      desired=`kubectl -n benchmark-operator get daemonsets backpack-$uuid | grep -v NAME | awk '{print $2}'`
      ready=`kubectl -n benchmark-operator get daemonsets backpack-$uuid | grep -v NAME | awk '{print $4}'`
      if [[ $desired -eq $ready ]]
      then
        echo "Backpack complete. Starting benchmark"
        break
      fi
    fi
    count=$((count + 1))
    if [[ $count -ne $max_count ]]
    then
      sleep 6
    else
      echo "Backpack failed to complete. Exiting"
      exit 1
    fi
  done
}

function check_es() {
  if [[ ${#} != 2 ]]; then
    echo "Wrong number of arguments: ${#}"
    return 1
  fi
  local uuid=$1
  local index=${@:2}
  for my_index in $index; do
    python3 tests/check_es.py -s $es_url -u $uuid -i $my_index \
      || return 1
  done
}
