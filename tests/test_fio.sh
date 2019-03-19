#!/usr/bin/env bash
set -xeo pipefail

# Instead of applying the cr, we should create different crs and
kubectl apply -f tests/test_crs/valid_fio.yaml
sleep 30
fio_client_pod=$(kubectl get pods -l app=fio-bench-server -o name | cut -d/ -f2)
sleep 150
# ensuring the run has actually happened
kubectl logs "$fio_client_pod" | grep "Run status"
