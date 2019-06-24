#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

function finish {
  echo "Cleaning up mongo"
  kubectl delete -f tests/test_crs/valid_mongo.yaml
  delete_operator
}

trap finish EXIT

function functional_test_mongo {
  apply_operator
  kubectl apply -f tests/test_crs/valid_mongo.yaml
  check_pods 2
  kubectl -n ripsaw wait --for=condition=Ready "pods/mongo-0" --timeout=200s
  kubectl -n ripsaw wait --for=condition=Ready "pods/mongo-1" --timeout=200s
  echo "mongo test: Success"
}
functional_test_mongo
