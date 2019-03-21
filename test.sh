#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

trap cleanup_resources EXIT

operator_requirements
update_operator_image
#
# Run functional test for workloads
#
# Test UPerf
/bin/bash tests/test_uperf.sh
wait_clean
#
# Test FIO
/bin/bash tests/test_fio.sh
wait_clean
#
# Test Sysbench
/bin/bash tests/test_sysbench.sh
wait_clean
