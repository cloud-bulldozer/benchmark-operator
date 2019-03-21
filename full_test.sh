#!/usr/bin/env bash
set -xeo pipefail

source tests/common.sh

trap cleanup_operator_resources EXIT

create_operator
update_operator_image
#
# Test all workloads without recreating operator pods
#
source tests/test_uperf.sh
functional_test_uperf
source tests/test_fio.sh
functional_test_fio
