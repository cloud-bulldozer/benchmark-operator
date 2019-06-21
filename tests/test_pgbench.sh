#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  echo "Cleaning up pgbench"
  kubectl delete -n ripsaw benchmark/pgbench-benchmark
  kubectl delete -n ripsaw deployment/postgres
  kubectl delete -n ripsaw configmap/postgres-config
  delete_operator
}

trap finish EXIT

# Note we don't test persistent storage here
function functional_test_pgbench {
  #figlet $(basename $0)
  apply_operator
  # stand up postgres deployment
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: ripsaw
  labels:
    app: postgres
data:
  POSTGRES_DB: cidb
  POSTGRES_USER: ci
  POSTGRES_PASSWORD: ci
  PGDATA: /var/lib/postgresql/data/pgdata
EOF
cat << EOF | kubectl apply -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: postgres
  namespace: ripsaw
spec:
  replicas: 1
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
                name: postgres-config
EOF
  postgres_pod=$(get_pod 'app=postgres' 300)
  sleep 10
  # get the postgres pod IP
  postgres_ip=$(kubectl get pod -n ripsaw $postgres_pod --template={{.status.podIP}})
  # deploy the test CR with the postgres pod IP
  sed s/host:/host:\ ${postgres_ip}/ tests/test_crs/valid_pgbench.yaml | kubectl apply -f -
  pgbench_pod=$(get_pod 'app=pgbench-client' 300)
  kubectl wait --for=condition=Initialized "pods/$pgbench_pod" -n ripsaw --timeout=60s
  kubectl wait --for=condition=Ready "pods/$pgbench_pod" -n ripsaw --timeout=60s
  kubectl wait --for=condition=Complete jobs -l 'app=pgbench-client' -n ripsaw --timeout=300s
  kubectl logs -n ripsaw $pgbench_pod | grep 'tps ='
  echo "pgbench test: Success"
}

functional_test_pgbench
