#!/usr/bin/env bash
set -x

source tests/common.sh

cleanup_operator_resources
update_operator_image

# Create a "gold" directory based off the current branch
mkdir gold
cp -pr * gold/

# The maximum number of concurrent tests to run at one time (0 for unlimited)
max_concurrent=3

eStatus=0

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

# Prep the results.xml file
echo '<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
   <testsuite name="CI Results" tests="NUMTESTS" failures="NUMFAILURES">' > results.xml

# Prep the results.markdown file
echo "Results for "$JOB_NAME > results.markdown
echo "" >> results.markdown
echo 'Test | Result | Retries| Duration (HH:MM:SS)' >> results.markdown
echo '-----|--------|--------|---------' >> results.markdown

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

# Run tests in parallel up to $max_concurrent at a time.
parallel -n 1 -a tests/my_tests -P $max_concurrent ./run_test.sh 

# Update and close JUnit test results.xml and markdown file
for test_dir in `cat tests/my_tests`
do
  cat $test_dir/results.xml >> results.xml
  cat $test_dir/results.markdown >> results.markdown
  cat $test_dir/ci_results >> ci_results
done

# Get number of successes/failures
testcount=`wc -l ci_results`
success=`grep Successful ci_results | awk -F ":" '{print $1}'`
failed=`grep Failed ci_results | awk -F ":" '{print $1}'`
failcount=`grep -c Failed ci_results`
echo "CI tests that passed: "$success
echo "CI tests that failed: "$failed
echo "Smoke test: Complete"

echo "   </testsuite>
</testsuites>" >> results.xml

sed -i "s/NUMTESTS/$testcount/g" results.xml
sed -i "s/NUMFAILURES/$failcount/g" results.xml

if [ `grep -c Failed ci_results` -gt 0 ]
then
  eStatus=1
fi
  
# Clean up our created directories
rm -rf gold test-* ci_results

exit $eStatus 
