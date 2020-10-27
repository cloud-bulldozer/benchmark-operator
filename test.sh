#!/bin/bash
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


function add_test_to_marker(){
    if [[ ${test_markers} == "-m" ]]; then
        test_markers="${test_markers} $1"
    elif [[ ${test_markers} != *"$1"* ]]; then 
        test_markers="${test_markers} or $1"
    fi
}

function git_diff_lookup(){
    file_name=$1
    if [[ $(echo ${file_name} | grep -E '(roles/fs-drift|e2e/benchmarks/fs-drift|e2e/tests/test_fs_drift.py)') ]]; then add_test_to_marker "fs_drift"; fi
    if [[ $(echo ${file_name} | grep -E '(roles/uperf|e2e/benchmarks/uperf|e2e/tests/test_uperf.py)') ]]; then add_test_to_marker "uperf"; fi
    if [[ $(echo ${file_name} | grep -E '(roles/fio_distributed|e2e/benchmarks/fiod|e2e/tests/test_fiod.py)') ]]; then add_test_to_marker "fiod"; fi
    if [[ $(echo ${file_name} | grep -E '(roles/iperf3|e2e/benchmarks/iperf3|e2e/tests/test_iperf3.py)') ]]; then add_test_to_marker "iperf3"; fi
    if [[ $(echo ${file_name} | grep -E '(roles/byowl|e2e/benchmarks/byowl|e2e/tests/test_byowl.py)') ]]; then add_test_to_marker "byowl"; fi
    if [[ $(echo ${file_name} | grep -E '(roles/sysbench|e2e/benchmarks/sysbench|e2e/tests/test_sysbench.py)') ]]; then add_test_to_marker "sysbench"; fi
    if [[ $(echo ${file_name} | grep -E '(roles/pgbench|e2e/benchmarks/pgbench|e2e/tests/test_pgbench.py)') ]]; then add_test_to_marker "pgbench"; fi
    if [[ $(echo ${file_name} | grep -E '(roles/ycsb|e2e/benchmarks/ycsb|e2e/tests/test_ycsb.py)') ]]; then add_test_to_marker "ycsb"; fi
    if [[ $(echo ${file_name} | grep -E '(roles/backpack|e2e/benchmarks/backpack|e2e/tests/test_backpack.py)') ]]; then add_test_to_marker "backpack"; fi
    if [[ $(echo ${file_name} | grep -E '(roles/hammerdb|e2e/benchmarks/hammerdb|e2e/tests/test_hammerdb.py)') ]]; then add_test_to_marker "hammerdb"; fi
    if [[ $(echo ${file_name} | grep -E '(roles/smallfile|e2e/benchmarks/smallfile|e2e/tests/test_smallfile.py)') ]]; then add_test_to_marker "smallfile"; fi
    if [[ $(echo ${file_name} | grep -E '(roles/vegeta|e2e/benchmarks/vegeta|e2e/tests/test_vegeta.py)') ]]; then add_test_to_marker "vegeta"; fi
    if [[ $(echo ${file_name} | grep -E '(roles/stressng|e2e/benchmarks/stressng|e2e/tests/test_stressng.py)') ]]; then add_test_to_marker "stressng"; fi
    if [[ $(echo ${file_name} | grep -E '(roles/scale_openshift|e2e/benchmarks/scale|e2e/tests/test_scale.py)') ]]; then add_test_to_marker "scale"; fi
    if [[ $(echo ${file_name} | grep -E '(roles/kube-burner|e2e/benchmarks/kube-burner|e2e/tests/test_kube_burner.py)') ]]; then add_test_to_marker "kube_burner"; fi
    if [[ $(echo ${file_name} | grep -E '(roles/servicemesh|e2e/benchmarks/servicemesh|e2e/tests/test_servicemesh.py)') ]]; then add_test_to_marker "servicemesh"; fi
}

function build_test_markers(){
    if [[ $1 != '' ]]; then
        test_markers="-m $1"
    else
        test_markers="-m"
        for item in $git_diff_files
        do
            git_diff_lookup ${item}
        done

    fi

}

eStatus=0
git_diff_files="$(git diff remotes/origin/master --name-only)"
test_markers="" 
cli_args="--es-server ${ES_SERVER}"



if [[ $test_choice != '' ]]; then
  echo "Running for requested tests"
  build_test_markers "${test_choice}"
elif [[ $test_choice == "all" || `echo "${git_diff_files}" | grep -cv /` -gt 0 || `echo ${git_diff_files} | grep -E "^(templates|build|deploy|group_vars|resources|e2e|roles/uuid)"` ]]; then
  echo "Running full test"
else
  echo "Running specific tests"
  build_test_markers ""
fi

virtualenv venv 
source venv/bin/activate
pip install -e e2e
pytest e2e "${test_markers}" ${cli_args}





