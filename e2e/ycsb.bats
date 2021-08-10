#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

export NAMESPACE=benchmark-operator
indexes=(ripsaw-ycsb-summary ripsaw-ycsb-results)


@test "ycsb-mongo" {
  CR=ycsb/ycsb-mongo.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark 300 || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
}

setup() {
  kubectl_exec apply -f - <<< '
---
apiVersion: v1
kind: Service
metadata:
 name: mongo
 labels:
   name: mongo
spec:
 ports:
 - port: 27017
   targetPort: 27017
 clusterIP: None
 selector:
   role: mongo
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
 name: mongo
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
       - containerPort: 27017'
}

setup_file() {
  basic_setup
}

teardown_file(){
  basic_teardown
}
