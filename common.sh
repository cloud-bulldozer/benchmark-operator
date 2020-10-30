#!/usr/bin/env bash

ERRORED=false
image_location=${RIPSAW_CI_IMAGE_LOCATION:-quay.io}
image_account=${RIPSAW_CI_IMAGE_ACCOUNT:-rht_perf_ci}
es_server=${ES_SERVER:-foo.esserver.com}
es_port=${ES_PORT:-80}
echo "using container image location $image_location and account $image_account"

function wait_clean {
  if [[ `kubectl get benchmarks.ripsaw.cloudbulldozer.io --all-namespaces` ]]
  then
    kubectl delete benchmarks -n my-ripsaw --all --ignore-not-found
  fi
  kubectl delete namespace my-ripsaw --ignore-not-found
}

function apply_operator {
  operator_requirements
  BENCHMARK_OPERATOR_IMAGE=${BENCHMARK_OPERATOR_IMAGE:-"quay.io/benchmark-operator/benchmark-operator:master"}
  cat resources/operator.yaml | \
    sed 's#quay.io/benchmark-operator/benchmark-operator:master#'$BENCHMARK_OPERATOR_IMAGE'#' | \
    kubectl apply -f -
  kubectl wait --for=condition=available "deployment/benchmark-operator" -n my-ripsaw --timeout=300s
}

function delete_operator {
  kubectl delete -f resources/operator.yaml
}

function marketplace_setup {
  kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/01_namespace.yaml
  kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/02_catalogsourceconfig.crd.yaml
  kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/03_operatorsource.crd.yaml
  kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/04_service_account.yaml
  kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/05_role.yaml
  kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/06_role_binding.yaml
  kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/07_upstream_operatorsource.cr.yaml
  kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/08_operator.yaml
}

function marketplace_cleanup {
  kubectl delete -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/07_upstream_operatorsource.cr.yaml
  kubectl delete -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/08_operator.yaml
  kubectl delete -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/06_role_binding.yaml
  kubectl delete -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/05_role.yaml
  kubectl delete -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/04_service_account.yaml
  kubectl delete -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/03_operatorsource.crd.yaml
  kubectl delete -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/02_catalogsourceconfig.crd.yaml
  kubectl delete -f https://raw.githubusercontent.com/operator-framework/operator-marketplace/master/deploy/upstream/01_namespace.yaml
}

function operator_requirements {
  kubectl apply -f resources/namespace.yaml
  kubectl apply -f deploy
  kubectl apply -f resources/crds/ripsaw_v1alpha1_ripsaw_crd.yaml
  kubectl -n my-ripsaw get roles
  kubectl -n my-ripsaw get rolebindings
  kubectl -n my-ripsaw get podsecuritypolicies
  kubectl -n my-ripsaw get serviceaccounts
  kubectl -n my-ripsaw get serviceaccount benchmark-operator -o yaml
  kubectl -n my-ripsaw get role benchmark-operator -o yaml
  kubectl -n my-ripsaw get rolebinding benchmark-operator -o yaml
  kubectl -n my-ripsaw get podsecuritypolicy privileged -o yaml
}

function backpack_requirements {
  kubectl apply -f resources/backpack_role.yaml
  if [[ `command -v oc` ]]
  then
    if [[ `oc get securitycontextconstraints.security.openshift.io` ]]
    then
      oc adm policy -n my-ripsaw add-scc-to-user privileged -z benchmark-operator
      oc adm policy -n my-ripsaw add-scc-to-user privileged -z backpack-view
    fi
  fi
}

function create_operator {
  operator_requirements
  apply_operator
}

function cleanup_resources {
  echo "Exiting after cleanup of resources"
  kubectl delete -f resources/crds/ripsaw_v1alpha1_ripsaw_crd.yaml
  kubectl delete -f deploy
}

function cleanup_operator_resources {
  delete_operator
  cleanup_resources
  wait_clean
}

function update_operator_image {
  tag_name="${NODE_NAME:-master}"
  if operator-sdk build $image_location/$image_account/benchmark-operator:$tag_name --image-builder podman; then
  # In case we have issues uploading to quay we will retry a few times
    for i in {1..3}; do
      podman push $image_location/$image_account/benchmark-operator:$tag_name && break
      echo "Could not upload image to quay. Exiting"
      exit 1
    done
  else
    echo "Could not build image. Exiting"
    exit 1
  fi
  sed -i "s|          image: quay.io/benchmark-operator/benchmark-operator:master*|          image: $image_location/$image_account/benchmark-operator:$tag_name # |" resources/operator.yaml
}

function error {
  if [[ $ERRORED == "true" ]]
  then
    exit
  fi

  ERRORED=true

  echo "Error caught. Dumping logs before exiting"
  echo "Benchmark operator Logs"
  kubectl -n my-ripsaw logs --tail=40 -l name=benchmark-operator -c benchmark-operator
  echo "Ansible sidecar Logs"
  kubectl -n my-ripsaw logs -l name=benchmark-operator -c ansible
}


