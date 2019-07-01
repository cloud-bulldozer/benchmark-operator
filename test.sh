#!/usr/bin/env bash
set -x

source tests/common.sh

cleanup_operator_resources
update_operator_image

failed=()
success=()
test_list=tests/test_list

pass=0

# Iterate over the tests listed in test_list. For quickest testing of an individual workload have 
# its test listed first in $test_list
for ci_test in `cat $test_list`
do
  # Re-deploy operator requirements before each test
  operator_requirements

  # Test ci
  if /bin/bash tests/$ci_test 
  then
    success=("${success[@]}" $ci_test)
    echo "$ci_test: Successful"
  else
    failed=("${failed[@]}" $ci_test)
    pass=1
    echo "$ci_test: Failed"
  fi
  
  # Ensure that all operator resources have been cleaned up after each test
  cleanup_operator_resources
done

echo "CI tests that passed: "${success[@]}
echo "CI tests that failed: "${failed[@]}
echo "Smoke test: Complete"

exit $pass
