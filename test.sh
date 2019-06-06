#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

trap cleanup_resources EXIT

wait_clean
operator_requirements
update_operator_image
#
# Run functional test for workloads
#
# Test UPerf
/bin/bash tests/test_uperf.sh
wait_clean
# Test iperf3
/bin/bash tests/test_iperf3.sh
wait_clean
#
# Test FIO
/bin/bash tests/test_fio.sh
wait_clean
# Test FIOD
/bin/bash tests/test_fiod.sh
wait_clean
#
# Test Sysbench
/bin/bash tests/test_sysbench.sh
wait_clean
#
# Test BYOWL
/bin/bash tests/test_byowl.sh
wait_clean
#
# Disabled standalone Couchbase test since it is duplicated below
# with YCSB, which requires the Couchbase infra
# Test Couchbase
#/bin/bash tests/test_couchbase.sh
#wait_clean
#
# Test YCSB w/ Couchbase
/bin/bash tests/test_ycsb-couchbase.sh
wait_clean
#
echo "Smoke test: successful"
