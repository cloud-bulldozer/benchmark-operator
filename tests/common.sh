#!/usr/bin/env bash

ERRORED=false
image_location=${RIPSAW_CI_IMAGE_LOCATION:-quay.io}
image_account=${RIPSAW_CI_IMAGE_ACCOUNT:-rht_perf_ci}
es_url=${ES_SERVER:-http://foo.esserver.com:9200}
echo "using container image location $image_location and account $image_account"

function populate_test_list {
  rm -f tests/iterate_tests

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


    # Check for changes in test scripts
    test_check=`echo $item | awk -F / '{print $2}'`

    if [[ $(echo ${test_check} | grep 'test_.*.sh') ]]; then echo ${test_check} >> tests/iterate_tests; fi
  done
}

function wait_clean {
  if [[ `kubectl get benchmarks.ripsaw.cloudbulldozer.io --all-namespaces` ]]
  then
    kubectl delete benchmarks -n my-ripsaw --all --ignore-not-found
  fi
  kubectl delete -f deploy/25_role.yaml -f deploy/35_role_binding.yaml --ignore-not-found
  kubectl delete namespace my-ripsaw --ignore-not-found
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
  BENCHMARK_OPERATOR_IMAGE=${BENCHMARK_OPERATOR_IMAGE:-"quay.io/benchmark-operator/benchmark-operator:master"}
  cat resources/operator.yaml | \
    sed 's#quay.io/benchmark-operator/benchmark-operator:master#'$BENCHMARK_OPERATOR_IMAGE'#' | \
    kubectl apply -f -
  kubectl wait --for=condition=available "deployment/benchmark-operator" -n my-ripsaw --timeout=300s
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
  kubectl apply -f resources/namespace.yaml
  kubectl apply -f deploy
  kubectl apply -f resources/crds/ripsaw_v1alpha1_ripsaw_crd.yaml
  kubectl -n my-ripsaw get roles
  kubectl -n my-ripsaw get rolebindings
  kubectl -n my-ripsaw get podsecuritypolicies
  kubectl -n my-ripsaw get serviceaccounts
  kubectl -n my-ripsaw get serviceaccount benchmark-operator -o yaml
  kubectl -n my-ripsaw get role benchmark-operator -o yaml
  kubectl -n my-ripsaw get rolebinding benchmark-operator -o yaml
  kubectl -n my-ripsaw get podsecuritypolicy privileged -o yaml
}

function backpack_requirements {
  kubectl apply -f resources/backpack_role.yaml
  if [[ `command -v oc` ]]
  then
    if [[ `oc get securitycontextconstraints.security.openshift.io` ]]
    then
      oc adm policy -n my-ripsaw add-scc-to-user privileged -z benchmark-operator
      oc adm policy -n my-ripsaw add-scc-to-user privileged -z backpack-view
    fi
  fi
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
  if operator-sdk build $image_location/$image_account/benchmark-operator:$tag_name --image-builder podman; then
  # In case we have issues uploading to quay we will retry a few times
    for i in {1..3}; do
      podman push $image_location/$image_account/benchmark-operator:$tag_name && break
      echo "Could not upload image to quay. Exiting"
      exit 1
    done
  else
    echo "Could not build image. Exiting"
    exit 1
  fi
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
  if [[ $ERRORED == "true" ]]
  then
    exit
  fi

  ERRORED=true

  echo "Error caught. Dumping logs before exiting"
  echo "Benchmark operator Logs"
  kubectl -n my-ripsaw logs --tail=200 -l name=benchmark-operator -c benchmark-operator
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
