#!/usr/bin/env bash

function check_status() {
  for i in {1..10}; do
    if [ `kubectl get pods | grep bench | wc -l` -gt $1 ]; then
      break
    else
      sleep 10
    fi
  done
}

function check_log(){
  for i in {1..10}; do
    if kubectl logs -f $1 | grep -q $2 ; then
      break;
    else
      sleep 10
    fi
  done
}
