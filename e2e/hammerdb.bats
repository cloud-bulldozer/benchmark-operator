#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

export NAMESPACE=benchmark-operator
ES_INDEX=ripsaw-hammerdb-results


@test "hammerdb-standard" {
  CR=hammerdb/hammerdb.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 300 || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
}

setup_file() {
  basic_setup
  kubectl apply -f - <<< '
---
apiVersion: v1
kind: Namespace
metadata:
  name: sql-server
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mssql-deployment
  namespace: sql-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mssql
  template:
    metadata:
      labels:
        app: mssql
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: mssql
        image: quay.io/cloud-bulldozer/mssql:latest
        ports:
        - containerPort: 1433
        resources:
          requests:
            memory: "2048Mi"
---
apiVersion: v1
kind: Service
metadata:
  name: mssql-deployment
  namespace: sql-server
spec:
  selector:
    app: mssql
  ports:
    - protocol: TCP
      port: 1433
      targetPort: 1433'
  kubectl rollout status -n sql-server deploy/mssql-deployment --timeout=60s
}

teardown_file(){
  kubectl delete ns sql-server --wait=false
  basic_teardown
}
