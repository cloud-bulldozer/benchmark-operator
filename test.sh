#!/usr/bin/env bash
set -x

source tests/common.sh

cleanup_operator_resources
update_operator_image

failed=()
success=()

git_diff_files="$(git diff remotes/origin/master --name-only)"
for file in ${git_diff_files}
do
  echo "$file" >> tests/git_diff
done

check_all_tests=$(check_full_trigger)
if [[ "$check_all_tests" != "True" ]]
then
  echo "checking which tests need to be run"
  populate_test_list "${git_diff_files}"
else
  echo "running all the tests"
  `cp tests/test_list tests/iterate_tests`
fi

test_list="$(cat tests/iterate_tests)"
echo "running test suit consisting of ${test_list}"

pass=0

testcount=0
failcount=0

# Prep the results.xml file
echo '<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
   <testsuite name="CI Results" tests="NUMTESTS" failures="NUMFAILURES">' > results.xml

# Prep the results.markdown file
echo "Results for "$JOB_NAME > results.markdown
echo "" >> results.markdown
echo 'Test | Result' >> results.markdown
echo '-----|-------' >> results.markdown

# Iterate over the tests listed in test_list. For quickest testing of an individual workload have
# its test listed first in $test_list
for ci_test in `cat tests/iterate_tests`
do
  # Re-deploy operator requirements before each test
  operator_requirements

  # Test ci
  if /bin/bash tests/$ci_test
  then
    success=("${success[@]}" $ci_test)
    echo "$ci_test: Successful"
    echo "      <testcase classname=\"CI Results\" name=\"$ci_test\"/>" >> results.xml
    echo "$ci_test | Pass" >> results.markdown
  else
    failed=("${failed[@]}" $ci_test)
    pass=1
    echo "$ci_test: Failed"
    echo "      <testcase classname=\"CI Results\" name=\"$ci_test\" status=\"$ci_test failed\">" >> results.xml
    echo "         <failure message=\"$ci_test failure\" type=\"test failure\"/>
      </testcase>" >> results.xml
    echo "$ci_test | Fail" >> results.markdown
    ((failcount++))
  fi

  ((testcount++))
  # Ensure that all operator resources have been cleaned up after each test
  cleanup_operator_resources
done

echo "CI tests that passed: "${success[@]}
echo "CI tests that failed: "${failed[@]}
echo "Smoke test: Complete"

# Update and close JUnit test results.xml
echo "   </testsuite>
</testsuites>" >> results.xml

sed -i "s/NUMTESTS/$testcount/g" results.xml
sed -i "s/NUMFAILURES/$failcount/g" results.xml

exit $pass
