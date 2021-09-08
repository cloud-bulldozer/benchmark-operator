# How to contribute

Contributions are always appreciated.

How to:
* [Submit Pull Request](#pull-request)
* [Container images](#container-images)
* [Add new workloads](#add-workload)
* [Test changes locally](#testing-your-workload-locally)
* [CI](#ci)

## Pull request

In order to submit a change or a PR, please fork the project and follow instructions:
```bash
$ git clone http://github.com/<me>/ripsaw
$ cd ripsaw
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

In the interactive rebase screen, set the first commit to `pick` and all others to `squash` (or whatever else you may need to do).

Push your rebased commits (you may need to force), then issue your PR.

## Add workload

Adding new workloads are always welcome, but before you submit PR:
please make sure you follow:
* [best practices](#best-practices-for-new-workloads).
* [add test to ci](#ci-add-test)
* [add workload guide](#additional-guidance-for-adding-a-workload)

### Ansible roles
Workloads are defined within Ansible roles. The roles are located under the `roles/` directory. You can create a new role template as follows:

- Simply copy an existing role and edit as needed

Review the Ansible [role documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html)

Tasks in the `roles/<role_name>/tasks/main.yml` playbook will be executed when the particular role is triggered in the operator from the Custom Resource (CR).

### Including new roles in the operator
A new role should be included in the [playbook](playbook.yml) with
condition(s) that will [trigger](#Workload-triggers) the role as follows:

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

### Workload triggers
[CRD](https://kubernetes.io/docs/tasks/access-kubernetes-api/custom-resources/custom-resource-definitions/) holds the definition of the resource.
The operator triggers roles based on the conditions defined in a CR ([example](config/samples/uperf/cr.yaml) which will influence which roles the
[playbook](playbook.yml) executes.
Other vars may be defined that can modify the workload run conditions.

For the sake of the example CR, please default all workloads to disabled.

Example CR:
```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: example-benchmark
  namespace: benchmark-operator
spec:
  workload:
    name: your_workload_name
    args:
      workers: 0
      my_key_1: my_value_1
      my_key_2: my_value_2
      my_dict:
        my_key_3: my_value_3
```

Note: The Benchmark has to be created in the namespace `benchmark-operator`

### Additional guidance for adding a workload
* Please keep the [workload status](README.md#workloads-status) updated
* To help users understand how the workload can be run, please add a guide similar
to [uperf](docs/uperf.md)
* Add the link for your workload guide to [installation guide](docs/installation.md#running-workloads)
* Ensure all resources created are within the `benchmark-operator` namespace, this can be done by setting namespace
to use `operator_namespace` var. This is to ensure that the resources aren't defaulted to current active
namespace which is what `ansible_operator_meta.namespace` would default to.
* All resources created as part of your role should use `trunc_uuid` ansible var in their names and labels, so
for example [fio-client job template](roles/fio-distributed/templates/client.yaml) has the name `fio-client` and label `app: fiod-client`, instead we'll append the var `trunc_uuid` to both
the name and label so it'll be `fio-client-{{ trunc_uuid }}` and label would be `app:fiod-client-{{ trunc_uuid }}`. The reason for this
is that 2 parallel runs of some benchmark aren't going to interfere with each other if each resource and its label is unique for that run.
We could've looked at using the full uuid but we hit an issue with character limit of 63 so using the truncated uuid which is the first 8 digits.

### Best practices for new workloads
The following steps are suggested for your workload to be added:
* The new role destroys any additional resources it created as part of role in
case of failure or when disabled. This ensures no interference with subsequent workloads.
* Please mention any additional cleanup required in your workload guide.

## Testing your workload locally

### The operator container image
Any changes to the [roles](roles/) tree or to the [playbook](playbook.yml) file will necessitate a new build of the operator container image.
The benchmark-operator container can be built and pushed to a public repository, which could be [quay](https://quay.io), using the provided Makefile.

To test with your own operator image, you will need to delete the current deployment and then build, push, and redeploy using your operator container image as follows:

```bash
# kubectl delete deployment -n benchmark-operator benchmark-controller-manager
# make image-build image-push deploy IMG=quay.io/<username>/benchmark-operator:testing
```
`:testing` is simply a tag. You can define different tags to use with your image, like `:latest` or `:master`

## CI
Currently we have a CI that runs against PRs.
You can learn more about CI at [work_in_progress]

### CI add test
To ensure that adding new a workload will not break other workloads and its
behavior can be predicted, we've mandated writing tests before PR can be merged.

If a new workload is added, please follow the instructions to add a testcase to
[test.sh](test.sh):
* copy an existing test like [uperf test](tests/test_uperf.sh)
* Add commands needed to setup the workload specific requirements if any
* Add a valid cr file to [test_crs](tests/test_crs/) directory for your workload
* Apply the cr and run a simple functional test to ensure that the expected behavior is asserted
* NOTE: make sure that your test script name has only underscores and no `-` in the name
