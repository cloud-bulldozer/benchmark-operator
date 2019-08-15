#!/bin/bash
set -x

source tests/common.sh

ci_dir=$1
ci_test=`echo $1 | sed 's/-/_/g'`

cd $ci_dir

# Apply the operator with customized namespace
kubectl apply -f resources/namespace.yaml

# Re-deploy operator requirements before each test
operator_requirements

# Test ci
if /bin/bash tests/$ci_test.sh
then
  echo "$ci_dir: Successful"
  echo "$ci_dir: Successful" >> ../ci_results
else
  echo "$ci_dir: Failed"
  echo "$ci_dir: Failed" >> ../ci_results
fi

# Ensure that all operator resources have been cleaned up after each test as well as the namespace
cleanup_operator_resources
kubectl delete -f resources/namespace.yaml
