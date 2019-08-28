#!/usr/bin/env bash
set -x

# update operator image
tag_name="${NODE_NAME:-master}"
operator-sdk build quay.io/rht_perf_ci/benchmark-operator:$tag_name
docker push quay.io/rht_perf_ci/benchmark-operator:$tag_name
sed -i "s|          image: quay.io/benchmark-operator/benchmark-operator:master*|          image: quay.io/rht_perf_ci/benchmark-operator:$tag_name # |" resources/operator.yaml


# Create a "gold" directory based off the current branch
mkdir gold
cp -pr * gold/

# The maximum number of concurrent tests to run at one time (0 for unlimited)
max_concurrent=3

eStatus=0

if [ -z $1 ]
then
  test_cases="all"
  echo "Test list supplied was empty, assuming all"
else
  test_cases=${1,,}
fi

if [[ "$test_cases" == "all" ]]
then
  grep tags tests/run_test.yml | awk '{ print substr($3, 1, length($3)-1)}' > tests/iterate_tests
else
  echo $test_cases | sed 's/,/\n/g' > tests/iterate_tests
fi

test_list="$(cat tests/iterate_tests)"
echo "running test suit consisting of ${test_list}"

# Massage the names into something that is acceptable for a namespace
sed 's/_/-/g' tests/iterate_tests > tests/my_tests

# Prep the results.xml file
echo '<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
   <testsuite name="CI Results" tests="NUMTESTS" failures="NUMFAILURES">' > results.xml

# Prep the results.markdown file
echo "Results for "$JOB_NAME > results.markdown
echo "" >> results.markdown
echo 'Test | Result | Retries| Duration (HH:MM:SS) | Failure Message (if failed)' >> results.markdown
echo '-----|--------|--------|---------|--------' >> results.markdown

# Create individual directories for each test
for ci_dir in `cat tests/my_tests`
do
  mkdir $ci_dir
  cp -pr gold/* $ci_dir/
  cd $ci_dir/
  my_dir=`pwd`
  # Edit the namespaces so we can run in parallel
  sed -i "s/my-ripsaw/my-ripsaw-$ci_dir/g" `grep -Rl my-ripsaw`
  sed -i "s?^ripsaw_dir.*?ripsaw_dir: $my_dir?g" tests/group_vars/all.yml
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
