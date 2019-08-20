
#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  echo "Cleaning up fs-drift"
  kubectl delete -f tests/test_crs/valid_fs_drift.yaml
  delete_operator
}

trap finish EXIT

function functional_test_fs_drift {
  figlet $(basename $0)
  apply_operator
  kubectl apply -f tests/test_crs/valid_fs_drift.yaml
  sleep 15
  fsdrift_pod=$(kubectl get pods -l app=fs-drift-benchmark --namespace my-ripsaw -o name | cut -d/ -f2 | grep client)
  echo fsdrift_pod $smallfile_pod
  wait_for "kubectl wait --for=condition=Initialized pods/$fsdrift_pod --namespace my-ripsaw --timeout=200s" "200s"
  $fsdrift_pod
  wait_for "kubectl wait --for=condition=complete -l app=smallfile-benchmark jobs --namespace my-ripsaw --timeout=100s"
  "100s" $fsdrift_pod
  sleep 30
  # ensuring the run has actually happened
  kubectl logs "$fsdrift_pod" --namespace my-ripsaw | grep "RUN STATUS"
  echo "fs-drift test: Success"
}

functional_test_fs_drift
