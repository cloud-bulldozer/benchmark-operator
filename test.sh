#!/usr/bin/env bash
set -x

source tests/common.sh

cleanup_operator_resources

# The maximum number of concurrent tests to run at one time (0 for unlimited)
max_concurrent=3

eStatus=0

git_diff_files="$(git diff remotes/origin/master --name-only)"

if [[ `echo "${git_diff_files}" | grep -cv /` -gt 0 || `echo ${git_diff_files} | grep -E "(build/|deploy/|group_vars/|resources/|/common.sh|/uuid)"` ]]; then
        echo "Running full test"
        cp tests/test_list tests/iterate_tests
else
        echo "Running specific tests"
        populate_test_list "${git_diff_files}"
fi

test_list="$(cat tests/iterate_tests)"
echo "running test suit consisting of ${test_list}"

if [[ ${test_list} == "" ]]; then
  echo "No tests to run"
  echo "Results for "$JOB_NAME > results.markdown
  echo "No tests to run" >> results.markdown
  exit 0
fi

# Massage the names into something that is acceptable for a namespace
sed 's/.sh//g' tests/iterate_tests | sort | uniq > tests/my_tests
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

# Update the operator image
update_operator_image

# Create a "gold" directory based off the current branch
mkdir gold

sed -i "s/ES_SERVER/$ES_SERVER/g" tests/test_crs/*
sed -i "s/ES_PORT/$ES_PORT/g" tests/test_crs/*

cp -pr * gold/

# Generate uuid
UUID=$(uuidgen)

# Create individual directories for each test
for ci_dir in `cat tests/my_tests`
do
  mkdir $ci_dir
  cp -pr gold/* $ci_dir/
  cd $ci_dir/
  # Edit the namespaces so we can run in parallel
  sed -i "s/my-ripsaw/my-ripsaw-$UUID-$ci_dir/g" `grep -Rl my-ripsaw`
  sed -i "s/sql-server/sql-server-$UUID/g" tests/mssql.yaml tests/test_crs/valid_hammerdb.yaml tests/test_hammerdb.sh
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
