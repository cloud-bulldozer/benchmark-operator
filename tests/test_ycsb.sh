#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up ycsb"
  wait_clean
}

trap error ERR
trap finish EXIT

function functional_test_ycsb {
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
apiVersion: apps/v1
kind: StatefulSet
metadata:
 name: mongo
 namespace: my-ripsaw
spec:
 selector:
   matchLabels:
     role: mongo
 serviceName: "mongo"
 replicas: 1
 selector:
   matchLabels:
     role: mongo
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
  token=$(oc -n openshift-monitoring sa get-token prometheus-k8s)
  sed -e "s/PROMETHEUS_TOKEN/${token}/g" tests/test_crs/valid_ycsb-mongo.yaml | kubectl apply -f -
  long_uuid=$(get_uuid 20)
  uuid=${long_uuid:0:8}

  ycsb_load_pod=$(get_pod "name=ycsb-load-$uuid" 300)
  wait_for "kubectl wait --for=condition=Initialized pods/$ycsb_load_pod -n my-ripsaw --timeout=500s" "500s" $ycsb_load_pod
  wait_for "kubectl wait --for=condition=Complete jobs -l name=ycsb-load-$uuid -n my-ripsaw --timeout=300s" "300s" $ycsb_load_pod

  indexes="ripsaw-ycsb-summary ripsaw-ycsb-results"
  if check_es "${long_uuid}" "${indexes}"
  then
    echo "ycsb test: Success"
  else
    echo "Failed to find data for ${test_name} in ES"
    kubectl logs -n my-ripsaw $ycsb_load_pod
    exit 1
  fi
}

figlet $(basename $0)
apply_operator
functional_test_ycsb
