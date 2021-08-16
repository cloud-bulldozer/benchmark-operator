# vi: ft=bash

uuid=""
suuid=""
ARTIFACTS_DIR=artifacts
NAMESPACE=benchmark-operator


basic_setup() {
  export PROMETHEUS_TOKEN=$(oc sa get-token -n openshift-monitoring prometheus-k8s)
  export ES_SERVER=https://search-perfscale-dev-chmf5l4sh66lvxbnadi4bznl3a.us-west-2.es.amazonaws.com
}

teardown() {
  kubectl_exec delete benchmark ${CR_NAME} --ignore-not-found
}

check_es() {
  if [[ -n ${indexes} ]]; then
    for index in "${indexes[@]}"; do
      echo "Looking for documents with uuid: ${uuid} in index ${index}"
      documents=$(curl -sS ${ES_SERVER}/${index}/_search?q=uuid.keyword:${uuid} | jq .hits.total.value)
      if [[ ${documents} -le 0 ]]; then
        die "${documents} documents found in index ${ES_INDEX}"
      fi
    done
  else
    echo "Looking for documents with uuid: ${uuid} in index ${ES_INDEX}"
    documents=$(curl -sS ${ES_SERVER}/${ES_INDEX}/_search?q=uuid.keyword:${uuid} | jq .hits.total.value)
    if [[ ${documents} -le 0 ]]; then
      die "${documents} documents found in index ${ES_INDEX}"
    fi
  fi
}

get_uuid() {
  echo "Waiting for UUID from ${1}"
  local timeout=300
  while [[ ${timeout} -gt 0 ]]; do
    uuid=$(kubectl_exec get benchmarks ${1} -o jsonpath="{.status.uuid}")
    if [[ -n ${uuid} ]]; then
      suuid=$(kubectl_exec get benchmarks ${1} -o jsonpath="{.status.suuid}")
      break
    fi
    if [[ ${timeout} -lt 0 ]]; then
      false
    fi
    sleep 1
    let timeout=$timeout-1
  done
}

check_benchmark() {
  local timeout=${1}
  while [[ ${timeout} -gt 0 ]]; do
    if [[ $(kubectl_exec get benchmark/${CR_NAME} -o jsonpath={.status.complete}) == 'true' ]]; then
      break
    fi
    if [[ ${timeout} -lt 0 ]]; then
      die "Timeout waiting for benchmark/${CR_NAME} to complete"
    fi
    sleep 10
    let timeout=$timeout-10
  done
  local state=$(kubectl_exec get benchmark/${CR_NAME} -o jsonpath={.status.state})
  if [[ ${state} != "Complete" ]]; then
    die "Benchmark state: ${state}"
  fi
}

die() {
  echo $1
  local BENCHMARK_LOGS=${ARTIFACTS_DIR}/${CR_NAME}
  mkdir -p ${BENCHMARK_LOGS}
  echo "Dumping logs at ${BENCHMARK_LOGS}"
  kubectl_exec get benchmark ${CR_NAME} -o yaml --ignore-not-found > ${BENCHMARK_LOGS}/${CR_NAME}.yaml
  kubectl_exec logs deployment/benchmark-controller-manager --tail=-1 -c manager > ${BENCHMARK_LOGS}/benchmark-controller-manager.log
  for pod in $(kubectl_exec get pod -l benchmark-uuid=${uuid} -o custom-columns="name:.metadata.name" --no-headers); do
    log_file=${BENCHMARK_LOGS}/${pod}.log
    echo "Saving log from pod ${pod} in ${log_file}"
    kubectl_exec logs --tail=-1 ${pod} > ${log_file}
  done
  false
}

get_benchmark_name() {
  benchmark_file=$1
  echo $(yq e '.metadata.name' $benchmark_file)
}

kubectl_exec() {
  kubectl -n ${NAMESPACE} $@
}
