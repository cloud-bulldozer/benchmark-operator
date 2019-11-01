#!/usr/bin/env bash
set -xeEo pipefail

source tests/common.sh

function finish {
  if [ $? -eq 1 ] && [ $ERRORED != "true" ]
  then
    error
  fi

  echo "Cleaning up backpack"
  kubectl delete -f tests/test_crs/valid_backpack.yaml
  delete_operator
}

trap error ERR
trap finish EXIT

function functional_test_byowl {
  figlet $(basename $0)
  apply_operator
  kubectl apply -f tests/test_crs/valid_backpack.yaml
  uuid=$(get_uuid 20)

  node_count=`kubectl get nodes | grep -v NAME | wc -l`
  until [ `kubectl -n my-ripsaw get daemonsets backpack-$uuid | grep -v NAME | awk '{print $4}'` -eq $node_count ] ; do
    sleep 5
  done
  echo $backpack_pod

  for pod in `kubectl -n my-ripsaw get pods -l name=backpack-$uuid | grep -v NAME | awk '{print $1}'`
  do
    if [[ `kubectl -n my-ripsaw exec $pod -- ls /tmp/stockpile.json` ]]
    then
      echo "Found stockpile.json on "$pod
    else
      echo "Could not find stockpile.json on "$pod
      echo "Backpack test: Fail"
      exit 1
    fi
  done

  echo "Backpack test: Success"
}

functional_test_byowl
