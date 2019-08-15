#!/usr/bin/env bash
set -x

source tests/common.sh

cleanup_operator_resources
update_operator_image

mkdir gold
cp -pr * gold/
max_concurrent=2

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

# Massage the names into something that is acceptable for a namespace
sed 's/.sh//g' tests/iterate_tests > tests/my_tests
sed -i 's/_/-/g' tests/my_tests

# Create individual directories for each test
for ci_dir in `cat tests/my_tests`
do
  mkdir $ci_dir
  cp -pr gold/* $ci_dir/
  cd $ci_dir/
  # Edit the namespaces so we can run in parallel
  sed -i "s/my-ripsaw/my-ripsaw-$ci_dir/g" `grep -Rl my-ripsaw`
  cd ..
done

# Run tests in parallel
cat tests/my_tests | xargs -n 1 -P $max_concurrent ./run_test.sh

# Get number of successes/failures
success=`grep Successful ci_results`
failed=`grep Failed ci_results`
echo "CI tests that passed: "$success
echo "CI tests that failed: "$failed
echo "Smoke test: Complete"

if [ `grep -c Failed ci_results` -gt 0 ]
then
  exit 1
fi
  
exit 0
