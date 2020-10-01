#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  [[ $check_logs == 1 ]] && kubectl logs -l app=kube-burner-benchmark-$uuid -n my-ripsaw
  echo "Cleaning up kube-burner"
  kubectl delete -f resources/kube-burner-role.yml --ignore-not-found
  kubectl delete ns -l kube-burner-uuid=${long_uuid}
  wait_clean
}


trap error ERR
trap finish EXIT

function functional_test_kubeburner {
  workload_name=$1
  metrics_profile=$2
  token=$(oc -n openshift-monitoring sa get-token prometheus-k8s)
  cr=tests/test_crs/valid_kube-burner.yaml
  check_logs=0
  wait_clean
  apply_operator
  kubectl apply -f resources/kube-burner-role.yml
  echo "Performing kube-burner: ${workload_name}"
  sed -e "s/WORKLOAD/${workload_name}/g" -e "s/PROMETHEUS_TOKEN/${token}/g" -e "s/METRICS_PROFILE/${metrics_profile}/g" ${cr} | kubectl apply -f -
  long_uuid=$(get_uuid 20)
  uuid=${long_uuid:0:8}

  pod_count "app=kube-burner-benchmark-$uuid" 1 900
  wait_for "kubectl wait -n my-ripsaw --for=condition=complete -l app=kube-burner-benchmark-$uuid jobs --timeout=500s" "500s"

  index="ripsaw-kube-burner"
  if check_es "${long_uuid}" "${index}"
  then
    echo "kube-burner ${workload_name}: Success"
  else
    echo "Failed to find data for kube-burner ${workload_name} in ES"
    check_logs=1
    exit 1
  fi
  kubectl delete ns -l kube-burner-uuid=${long_uuid}
}

figlet $(basename $0)
functional_test_kubeburner cluster-density metrics-aggregated.yaml
functional_test_kubeburner kubelet-density metrics.yaml
functional_test_kubeburner kubelet-density-heavy metrics.yaml
