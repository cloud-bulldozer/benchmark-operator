#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

ES_INDEX=image-pull-results


@test "image_pull-standard" {
  CR=image_pull/image_pull.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid "${CR_NAME}"
  check_benchmark 600
  check_es
}

setup_file() {
  basic_setup
}
