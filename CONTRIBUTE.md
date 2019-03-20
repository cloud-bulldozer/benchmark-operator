# How to contribute

Contributions are always appreciated.

How to:
* [Submit Pull Request](#Pull-request)
* [Add new workloads](#Add-workload)
* [Test changes locally](#Test-workload-locally)
* [CI]

## Pull request

Inorder to submit a change or a PR, please fork the project and follow instructions:
```bash
$ git clone http://github.com/<me>/benchmark-operator
$ cd benchmark-operator
$ git checkout -b <branch_name>
$ <make change>
$ git add <changes>
$ git commit -a
$ <insert good message>
$ git push
```

If there are mutliple commits, please rebase/squash multiple commits
before creating the PR by following:

```bash
$ git checkout <my-working-branch>
$ git rebase -i HEAD~<num_of_commits_to_merge>
   -OR-
$ git rebase -i <commit_id_of_first_change_commit>
```
In the interactive rebase screen, set the first commit to `pick` and all others to `squash` (or whatever else you may need to do; RTFM).

Push your rebased commits (you may need to force), then issue your PR.

## Add workload

Adding new workloads are always welcome, but before you submit PR:
please make sure you follow:
* [best practices](#best-practices-for-new-workloads).
* [add test to ci](#CI-add-test)
* [add workload guide](#add-workload-guide)

### Ansible roles
Workloads are defined within Ansible roles. The roles are located under the `roles/` directory. You can create a new role template a few different ways.

- Simply copy an existing role and edit as needed
- Run the `ansible-galaxy init <role_name>` command
- Pull a blank template from [ansible-roles](https://github.com/ansible-roles/ansible-role-template)

Review the Ansible [role documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html)

Tasks in the `roles/<role_name>/tasks/main.yml` playbook will be executed when the particular role is triggered in the operator from the Custom Resource (CR).

### Including new roles in the operator
New roles should be included in the [playbook](playbook.yml) with
condition that'd [trigger](#Workload-triggers) the role as follows:

Example `playbook.yml`:
```yaml
- hosts: localhost
  gather_facts: no
  tasks:
  <existing_role_definitions>
  - include_role:
      name: "my-new-role"
    when: my-new-role.condition
```

### Workload container images
Images for workload containers must be hosted somewhere remotely accessible. You will likely reference those image URLs in your role.
Dockerfiles to build workload images should be maintained in the [workloads](workloads/) directory as `<role_name>-Dockerfile`.
These should be buildable by our CI system for maintaining a central public image repository.

### Workload triggers
[CRD](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/) holds the definition of the resource.
So please append your definitions to [crd](deploy/crds/bench_v1alpha1_bench_crd.yaml).
The resources are then mentioned in a [CR](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) that operator will look for based on the CRD passed.
The operator then triggers roles based on conditions thus [cr](deploy/crds/bench_v1alpha1_bench_cr.yaml) will influence run of [playbook](playbook.yml)
Other vars may be defined that can modify the workload run conditions.

For the sake of the example CR, please default all workloads to disabled.

Example CR:
```yaml
apiVersion: bench.example.com/v1alpha1
kind: Bench
metadata:
  name: example-bench
spec:
  <existing_cr_entries>
  my-new-role:
    # To disable, set workers to 0
    workers: 0
    my_key_1: my_value_1
    my_key_2: my_value_2
    my_dict:
      my_key_3: my_value_3
    when: my-new-role.condition
```

### Add workload guide
* Keep [workload status](README.md#workloads-status) updated
* To help users understand how the workload can be run, please add a guide similar
to [uperf](docs/uperf.md)
* Add the link for your workload guide to [installation guide](docs/installation.md#running-workloads)

### Best practices for new workloads
The following steps are suggested for your workload to be added:
* The new role destroys any additional resources it created as part of role in
case of failure or when disabled. This ensures no interference with subsequent workloads.
* Please mention any additional cleanup required in your workload guide.

## Test workload locally

### The operator container image
Any changes to the [roles](roles/) tree or to the [playbook](playbook.yml) file necessitates a new build of the operator container image.
The container is built using the [Operator SDK](https://github.com/operator-framework/operator-sdk) and pushed to a public repository.
The public repository could be quay in which case you'll need to:

```bash
$ operator-sdk build quay.io/<username>/benchmark-operator:testing
$ docker push quay.io/<username>/benchmark-operator:testing
```

To test with your own operator image, you will need the [operator](deploy/operator.yml) file to point the container image to your testing version.
Be sure to do this outside of your git tree to avoid mangling the official file that points to our stable image.

This can be done as follows:

```bash
# sed -i 's|          image: *|          image: quay.io/<username>/benchmark-operator:latest # |' deploy/operator.yaml
```

You can then redeploy operator
```bash
# kubectl delete -f deploy/operator.yaml
# kubectl apply -f deploy/operator.yaml
```
Redefine CRD
```bash
# kubectl delete -f deploy/crds/bench_v1alpha1_bench_crd.yaml
# kubectl delete -f deploy/crds/bench_v1alpha1_bench_crd.yaml
```
Apply a new CR
```bash
# kubectl delete -f deploy/crds/bench_v1alpha1_bench_cr.yaml
# kubectl delete -f deploy/crds/bench_v1alpha1_bench_cr.yaml
```

## CI
Currently we've a CI that runs against PRs.
You can learn more about CI at [work_in_progress]

### CI add test
To ensure that adding new a workload will not break other workloads and it's
behavior can be predicted, we've mandated writing tests before PR can be merged.

If a new workload is added, please follow the instructions to add a testcase to
[test.sh](test,sh):
* Add commands needed to setup the workload specific requirements if any
* Create a tests/test_<workload>.sh that has the functional test
* Add a valid cr file to [test_crs](tests/test_crs/) directory for your workload
* Add an invalid cr file to same directory
* Apply the cr and run a simple functional test to ensure that the expected behavior is asserted
* Delete the cr and redo for the invalid cr
