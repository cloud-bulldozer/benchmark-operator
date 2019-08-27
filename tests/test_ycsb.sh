#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up ycsb"
  kubectl delete -n my-ripsaw benchmark/ycsb-mongo-benchmark
  kubectl delete -n my-ripsaw statefulset/mongo
  kubectl delete -n my-ripsaw service/mongo
  delete_operator
}

trap error ERR
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
         command: ["/bin/sh"]
         args:  ["-c", "mkdir -p /tmp/data/db; mongod --bind_ip 0.0.0.0 --dbpath /tmp/data/db"]
         ports:
           - containerPort: 27017
EOF
  kubectl apply -f tests/test_crs/valid_ycsb-mongo.yaml
  uuid=$(get_uuid 20)
  ycsb_load_pod=$(get_pod "name=ycsb-load-$uuid" 300)
  wait_for "kubectl wait --for=condition=Initialized pods/$ycsb_load_pod -n my-ripsaw --timeout=60s" "60s" $ycsb_load_pod
  wait_for "kubectl wait --for=condition=Complete jobs -l name=ycsb-load-$uuid -n my-ripsaw --timeout=300s" "300s" $ycsb_load_pod
  kubectl logs -n my-ripsaw $ycsb_load_pod | grep 'Starting test'
  echo "ycsb test: Success"
}

functional_test_ycsb
