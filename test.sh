#!/usr/bin/env bash
set -x

# The maximum number of concurrent tests to run at one time (0 for unlimited). This can be overriden with -p
max_concurrent=3

# Presetting test_choice to be blank. 
test_choice=''

while getopts p:t:s: flag
do
    case "${flag}" in
        p) max_concurrent=${OPTARG};;
        t) test_choice=${OPTARG};;
        s) ES_SERVER=${OPTARG};;
    esac
done

if ! command -v yq &> /dev/null
then
    echo "yq not installed, installing"
    wget https://github.com/mikefarah/yq/releases/download/v4.9.6/yq_linux_amd64 -O /usr/local/bin/yq && chmod +x /usr/local/bin/yq
fi


source tests/common.sh

eStatus=0

git_diff_files="$(git diff remotes/origin/master --name-only)"

if [[ $test_choice != '' ]]; then
  echo "Running for requested tests"
  populate_test_list "${test_choice}"
elif [[ `echo "${git_diff_files}" | grep -cv /` -gt 0 || `echo "${git_diff_files}" | grep -E "^(templates|build|deploy|group_vars|resources|tests/common.sh|roles/uuid)"` ]]; then
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
sed 's/\.sh//g' tests/iterate_tests | sort | uniq > tests/my_tests
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

# Create a "gold" directory based off the current branch
mkdir gold

# Generate uuid
NEW_UUID=$(uuidgen)
UUID=${NEW_UUID%-*}

#Tag name
tag_name="${NODE_NAME:-master}"

sed -i "s#ES_SERVER#$ES_SERVER#g" tests/test_crs/*
cp -pr * gold/

# Create individual directories for each test
for ci_dir in `cat tests/my_tests`
do
  mkdir $ci_dir
  cp -pr gold/* $ci_dir/
done

delete_operator || true
oc delete namespace benchmark-operator --ignore-not-found
kubectl delete benchmarks -n benchmark-operator --ignore-not-found --all
apply_operator


# Run scale test first if it is in the test list
scale_test="false"
if [[ `grep test-scale-openshift tests/my_tests` ]]
then
  scale_test="true"
  sed -i '/test-scale-openshift/d' tests/my_tests
  ./run_test.sh test-scale-openshift
fi

# Run tests in parallel up to $max_concurrent at a time.
parallel -n 1 -a tests/my_tests -P $max_concurrent ./run_test.sh 
if [[ $scale_test == "true" ]]
then
  echo "test-scale-openshift" >> tests/my_tests
fi

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
