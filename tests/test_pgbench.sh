#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up pgbench"
  kubectl delete -n my-ripsaw benchmark/pgbench-benchmark
  kubectl delete -n my-ripsaw deployment/postgres
  kubectl delete -n my-ripsaw configmap/postgres-config
  delete_operator
}

trap error ERR
trap finish EXIT

# Note we don't test persistent storage here
function functional_test_pgbench {
  figlet $(basename $0)
  apply_operator
  # stand up postgres deployment
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: my-ripsaw
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
  namespace: my-ripsaw
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
  # get the postgres pod IP
  postgres_ip=0
  counter=0
  until [[ $postgres_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ||  $counter -eq 10 ]]; do
    let counter+=1
    postgres_ip=$(kubectl get pod -n my-ripsaw $postgres_pod --template={{.status.podIP}})
    sleep 2
  done
  # deploy the test CR with the postgres pod IP
  sed s/host:/host:\ ${postgres_ip}/ tests/test_crs/valid_pgbench.yaml | kubectl apply -f -
  uuid=$(get_uuid 20)

  wait_for_backpack $uuid

  pgbench_pod=$(get_pod "app=pgbench-client-$uuid" 300)
  wait_for "kubectl wait --for=condition=Initialized pods/$pgbench_pod -n my-ripsaw --timeout=60s" "60s" $pgbench_pod
  wait_for "kubectl wait --for=condition=Ready pods/$pgbench_pod -n my-ripsaw --timeout=60s" "60s" $pgbench_pod
  wait_for "kubectl wait --for=condition=Complete jobs -l app=pgbench-client-$uuid -n my-ripsaw --timeout=300s" "300s" $pgbench_pod
  kubectl logs -n my-ripsaw $pgbench_pod | grep 'tps ='
  echo "pgbench test: Success"
}

functional_test_pgbench
