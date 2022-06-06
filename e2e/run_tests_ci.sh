#!/bin/bash

select_tests(){
  for f in $(git diff --name-only origin/master); do
    found=false
    while read -r t; do
      regex=$(echo ${t} | cut -d : -f 1)
      test_filter=$(echo ${t} | cut -d : -f 2)
      # File found in test_map
      if echo $f | grep -qE ${regex}; then
        found=true
        # Check if test was previously added
        if ! echo "${BATS_TESTS}" | grep -q "${test_filter}"; then
          if [[ ${BATS_TESTS} != "" ]]; then
            BATS_TESTS+="|"
          fi
          BATS_TESTS+="${test_filter}"
        fi
        break
      fi
    done < e2e/test_map
    # If one of the modified files is not present in the test_map, we exit the loop and
    # run all tests
    if [[ ${found} == "false" ]]; then
      echo "File ${f} not found in test_map, running all tests"
      BATS_TESTS=.
      break
    fi
  done
  export BATS_TESTS
}

if [[ -z ${BATS_TESTS} ]]; then
  select_tests
fi
make e2e-tests
