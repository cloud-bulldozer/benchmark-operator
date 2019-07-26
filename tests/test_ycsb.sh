#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  echo "Cleaning up ycsb"
  kubectl delete -n my-ripsaw benchmark/ycsb-mongo-benchmark
  kubectl delete -n my-ripsaw statefulset/mongo
  kubectl delete -n my-ripsaw service/mongo
  delete_operator
}

trap finish EXIT

function functional_test_ycsb {
  figlet $(basename $0)
  apply_operator
  # stand up mongo deployment
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
 name: mongo
 namespace: my-ripsaw
 labels:
   name: mongo
spec:
 ports:
 - port: 27017
   targetPort: 27017
 clusterIP: None
 selector:
   role: mongo
EOF
cat << EOF | kubectl apply -f -
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
 name: mongo
 namespace: my-ripsaw
spec:
 serviceName: "mongo"
 replicas: 1
 template:
   metadata:
     labels:
       role: mongo
       environment: test
   spec:
     terminationGracePeriodSeconds: 10
     containers:
       - name: mongo
         image: mongo
         command:
           - mongod
           - "--smallfiles"
           - "--bind_ip"
           - 0.0.0.0
         ports:
           - containerPort: 27017
       - name: mongo-sidecar
         image: cvallance/mongo-k8s-sidecar
         env:
           - name: MONGO_SIDECAR_POD_LABELS
             value: "role=mongo,environment=test"
EOF
  kubectl apply -f tests/test_crs/valid_ycsb-mongo.yaml
  ycsb_load_pod=$(get_pod 'name=ycsb-load' 300)
  kubectl wait --for=condition=Initialized "pods/$ycsb_load_pod" -n my-ripsaw --timeout=60s
  kubectl wait --for=condition=Complete jobs -l 'name=ycsb-load' -n my-ripsaw --timeout=300s
  kubectl logs -n my-ripsaw $ycsb_load_pod | grep 'Starting test'
  echo "ycsb test: Success"
}

functional_test_ycsb
