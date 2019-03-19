#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

# Instead of applying the cr, we should create different crs and
kubectl apply -f tests/test_crs/valid_uperf.yaml
check_status 2
uperf_client_pod=$(kubectl get pods -l app=uperf-bench-client -o name | cut -d/ -f2)

check_log $uperf_client_pod "Success"
#timeout 500 kubectl logs -f $uperf_client_pod

kubectl get pods -l name=benchmark-operator -o name | cut -d/ -f2 | xargs -I{} kubectl exec {} -- cat /tmp/current_run

# ensuring that uperf actually ran and we can access metrics
kubectl logs "$uperf_client_pod" | grep Success
