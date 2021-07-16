#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up pgbench"
  wait_clean
}

trap error ERR
trap finish EXIT

# Note we don't test persistent storage here
function functional_test_pgbench {
  # stand up postgres deployment
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: benchmark-operator
  labels:
    app: postgres
data:
  POSTGRES_DB: cidb
  POSTGRES_USER: ci
  POSTGRES_PASSWORD: ci
  PGDATA: /var/lib/postgresql/data/pgdata
EOF
cat << EOF | kubectl apply -f -
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
                name: postgres-config
EOF
  postgres_pod=$(get_pod 'app=postgres' 300)
  # get the postgres pod IP
  postgres_ip=0
  counter=0
  until [[ $postgres_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ||  $counter -eq 10 ]]; do
    let counter+=1
    postgres_ip=$(kubectl get pod -n benchmark-operator $postgres_pod --template={{.status.podIP}})
    sleep 2
  done
  # deploy the test CR with the postgres pod IP
  cr=tests/test_crs/valid_pgbench.yaml
  delete_benchmark $cr
  benchmark_name=$(get_benchmark_name $cr)
  sed s/host:/host:\ ${postgres_ip}/ $cr | kubectl apply -f -
  long_uuid=$(get_uuid $benchmark_name)
  uuid=${long_uuid:0:8}

  pgbench_pod=$(get_pod "app=pgbench-client-$uuid" 300)
  check_benchmark_for_desired_state $benchmark_name Complete 500s

  index="ripsaw-pgbench-summary ripsaw-pgbench-raw"
  if check_es "${long_uuid}" "${index}"
  then
    echo "pgbench test: Success"
  else
    echo "Failed to find data for PGBench in ES"
    kubectl logs -n benchmark-operator $pgbench_pod
    exit 1
  fi
  delete_benchmark $cr
}

figlet $(basename $0)
functional_test_pgbench
