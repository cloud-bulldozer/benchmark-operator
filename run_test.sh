#!/bin/bash
set -x

ci_dir=$1
ci_test=`echo $1 | sed 's/-/_/g'`
retries=1

figlet $ci_test

cd $ci_dir

source tests/common.sh

count=0

# Run the test up to a max of $retries
while [ $count -le $retries ]
do
  wait_clean

  # Test ci
  if /bin/bash tests/$ci_test.sh > $ci_test.out 2>&1
  then
    # if the test passes update the results and complete
    echo "$ci_dir: Successful"
    echo "$ci_dir: Successful" > ci_results
    echo "      <testcase classname=\"CI Results\" name=\"$ci_test\"/>" > results.xml
    echo "$ci_test | Pass | $count" > results.markdown 
    count=$retries
  else
    # if the test failed check if we have done the max retries
    if $count -lt $retries
    then
      echo "$ci_dir: Failed. Retrying"
      echo "$ci_dir: Failed. Retrying" >> $ci_test.out
    else
      echo "$ci_dir: Failed retry" 
      echo "$ci_dir: Failed" > ci_results
      echo "      <testcase classname=\"CI Results\" name=\"$ci_test\" status=\"$ci_test failed\">" > results.xml
      echo "         <failure message=\"$ci_test failed\" type=\"test failure\"/>
      </testcase>" >> results.xml
      echo "$ci_test | Fail | $count" > results.markdown
      echo "Logs for "$ci_dir

      # Display the error log since we have failed to pass
      cat $ci_test.out
    fi
  fi
  ((count++))
done
wait_clean
