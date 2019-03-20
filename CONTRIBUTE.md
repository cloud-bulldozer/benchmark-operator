# How to contribute?

The most simplest way...

## Fork the project
```bash
$ git clone http://github.com/<me>/benchmark-operator
$ cd benchmark-operator
$ <make change>
$ git add <changes>
$ git commit -a
$ <insert good message>
$ git push
```

## Make a pull request
Rebase/squash multiple commits before creating the PR
```bash
$ git checkout <my-working-branch>
$ git rebase -i HEAD~<num_of_commits_to_merge>
   -OR-
$ git rebase -i <commit_id_of_first_change_commit>
```
In the interactive rebase screen, set the first commit to `pick` and all others to `squash` (or whatever else you may need to do; RTFM).

Push your rebased commits (you may need to force), then issue your PR.

# How do I contribute a workload?
## Ansible roles
Workloads are defined within Ansible roles. The roles are located under the `roles/` directory. You can create a new role template a few different ways.

- Simply copy an existing role and edit as needed
- Run the `ansible-galaxy init <role_name>` command
- Pull a blank template from https://github.com/ansible-roles/ansible-role-template

Review the Ansible role documentation here: https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html

Tasks in the `roles/<role_name>/tasks/main.yml` playbook will be executed when the particular role is triggered in the operator from the Custom Resource (CR).

## Including new roles in the operator
New roles should be appended to the `playbook.yml` file in the root of the project along with the condition under which it is triggered by the operator (based on vars in the CR, as described below).

Example `playbook.yml`:
```yaml
- hosts: localhost
  gather_facts: no
  tasks:
  <existing_role_definitions>
  - include_role:
      name: "my-new-role"
    when: my-new-role is defined and my-new-role.workers > 0
```

## Adding workload triggers and vars to the custom resource
A sample CR file is located in the project under the `deploy/crds/` directory. Append the definitions for your new workload here. The vars from this file will feed into the `playbook.yml` defined above, so make sure the conditions defined there will be included here. Other vars may be defined that can modify the workload run conditions.

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
```

# How do I test a workload?
## Workload container images
Images for workload containers must be hosted somewhere remotely accessible. You will likely reference those image URLs in your `roles/<role_name>/tasks/main.yml` file or other places within your role.

As necessary, Dockerfiles to build workload images should be maintained in the `workloads/` directory as `<role_name>-Dockerfile`. These should be buildable by our CI system for maintaining a central public image repository.

## The operator container image
Any changes to the `roles/` tree or to the `playbook.yml` file will necessitate a new build of the operator container image. The container is built using the [Operator SDK](https://github.com/operator-framework/operator-sdk) and pushed to a public repository. For example, to build and host on [quay.io](https://quay.io):

```bash
$ operator-sdk build quay.io/<username>/benchmark-operator:testing
$ docker push quay.io/<username>/benchmark-operator:testing
```

To test with your own operator image, you will need to edit a copy of the `deploy/operator.yaml` file to point the container image to your testing version. Be sure to do this outside of your git tree to avoid mangling the official file that points to our stable image.

```yaml
...
spec:
...
  template:
...
    spec:
...
      containers:
        - name: benchmark-operator
          image: quay.io/<username>/benchmark-operator:testing
...
```
