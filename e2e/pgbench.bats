#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

export NAMESPACE=benchmark-operator
indexes=(ripsaw-pgbench-summary ripsaw-pgbench-raw)


@test "pgbench-standard" {
  CR=pgbench/pgbench.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark 300 || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
}


setup_file() {
  basic_setup
  kubectl apply -n ${NAMESPACE} -f - <<< '
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  labels:
    app: postgres
data:
  POSTGRES_DB: cidb
  POSTGRES_USER: ci
  POSTGRES_PASSWORD: ci
  PGDATA: /var/lib/postgresql/data/pgdata
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: benchmark-operator
spec:
  selector:
    matchLabels:
      app: postgres
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:10.4
        imagePullPolicy: "IfNotPresent"
        ports:
        - containerPort: 5432
        envFrom:
        - configMapRef:
            name: postgres-config'
  kubectl_exec rollout status deploy/postgres --timeout=60s
  export POSTGRES_IP=$(kubectl_exec get pod -l app=postgres -o jsonpath="{.items[*].status.podIP}")
}

teardown_file(){
  basic_teardown
}
