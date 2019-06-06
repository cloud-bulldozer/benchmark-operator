#!/usr/bin/env bash
set -xeo pipefail

source CI/common.sh

trap cleanup_operator_resources EXIT

create_operator
update_operator_image
#
# Test all workloads without recreating operator pods
#
source CI/test_uperf.sh
functional_test_uperf
source CI/test_fio.sh
functional_test_fio
source CI/test_sysbench.sh
functional_test_sysbench
