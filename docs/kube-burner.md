# Kube-burner

[kube-burner](https://github.com/cloud-bulldozer/kube-burner)

## Running kube-burner

Given that you followed instructions to deploy operator. Kube-burner needs an additional serviceaccount and clusterrole to run. Available at [kube-burner-role.yml](../resources/kube-burner-role.yml)
You can modify kube-burner's [cr.yaml](../resources/crds/ripsaw_v1alpha1_kube-burner_cr.yaml) to make it fit your requirements.

## Supported workloads

Ripsaw's kube-burner integration supports the following workloads:

- cluster-density
- kubelet-density
- kubelet-density-heavy

The workload is specified by the parameter `workload` from the `args` object of the configuration.

