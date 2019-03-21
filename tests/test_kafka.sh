#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  echo "Cleaning up kafka"
  kubectl delete -f tests/test_crs/valid_kafka.yaml
  strimzi_csv=$(kubectl -n ripsaw get clusterserviceversion |grep strimzi | awk '{print$1}')
  kubectl -n ripsaw delete clusterserviceversion $strimzi_csv
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
    pod_name=$(kubectl -n ripsaw get pods -l $1 -o name | cut -d/ -f2)
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


trap finish EXIT


# Note we don't test persistent storage here
function functional_test_kafka {
  apply_operator
  kubectl apply -f tests/test_crs/valid_kafka.yaml
  strimzi_operator_pod=$(get_pod 'name=strimzi-cluster-operator' 300)
  kubectl -n ripsaw wait --for=condition=Initialized "pods/$strimzi_operator_pod" --timeout=60s
  kubectl -n ripsaw wait --for=condition=Ready "pods/$strimzi_operator_pod" --timeout=300s
  kafka_app_pod=$(get_pod 'statefulset.kubernetes.io/pod-name=kafka-benchmark-kafka-2' 600)
  kubectl -n ripsaw wait --for=condition=Initialized "pods/$kafka_app_pod" --timeout=60s
  kubectl -n ripsaw wait --for=condition=Ready "pods/$kafka_app_pod" --timeout=300s
}

functional_test_kafka
