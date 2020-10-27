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

## Container Images

Custom container image definitions are maintained in [magazine](https://github.com/cloud-bulldozer/magazine).
We use quay for all storing all our custom container images, and if you're adding a new
workload and not sure of where to add/maintain the container image. We highly recommend, to
add the Dockerfile to magazine, as we've automation setup for updating images in Quay, when
a git push happens to magazine.

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
The operator triggers roles based on the conditions defined in a CR ([example](resources/crds/ripsaw_v1alpha1_uperf_cr.yaml)) which will influence which roles the
[playbook](playbook.yml) executes.
Other vars may be defined that can modify the workload run conditions.

For the sake of the example CR, please default all workloads to disabled.

Example CR:
```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: example-benchmark
  namespace: my-ripsaw
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

Note: The Benchmark has to be created in the namespace `my-ripsaw`

### Additional guidance for adding a workload
* Please keep the [workload status](README.md#workloads-status) updated
* To help users understand how the workload can be run, please add a guide similar
to [uperf](docs/uperf.md)
* Add the link for your workload guide to [installation guide](docs/installation.md#running-workloads)
* Ensure all resources created are within the `my-ripsaw` namespace, this can be done by setting namespace
to use `operator_namespace` var. This is to ensure that the resources aren't defaulted to current active
namespace which is what `meta.namespace` would default to.
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
The container is built using the [Operator SDK](https://github.com/operator-framework/operator-sdk) and pushed to a public repository.
The public repository could be [quay](https://quay.io) in which case you'll need to:

```bash
$ operator-sdk build quay.io/<username>/benchmark-operator:testing --image-builder podman 
$ podman push quay.io/<username>/benchmark-operator:testing
```

Note: you can also use docker, and no, we'll not judge ;)

`:testing` is simply a tag. You can define different tags to use with your image, like `:latest` or `:master`

To test with your own operator image, you will need the [operator](resources/operator.yml) file to point the container image to your testing version.
Be sure to do this outside of your git tree to avoid mangling the official file that points to our stable image.

This can be done as follows:

```bash
$ sed 's/image:.*/image: quay.io\/<username>\/benchmark-operator:testing/' resources/operator.yaml > /my/testing/operator.yaml
```

You can then redeploy operator
```bash
# kubectl delete -f resources/operator.yaml
# kubectl apply -f /my/testing/operator.yaml
```
Redefine CRD
```bash
# kubectl apply -f resources/crds/ripsaw_v1alpha1_ripsaw_crd.yaml
```
Apply a new CR
```bash
# kubectl apply -f resources/crds/ripsaw_v1alpha1_uperf_cr.yaml
```

## CI
Currently we have a CI that runs against PRs.
You can learn more about CI at [work_in_progress]

### Adding CI Tests

We use [pytest](https://docs.pytest.org/en/stable/) to run our operator tests. We have a test framework inside this repo under `e2e` with all tests located at `e2e/tests`.

Once you've added your new benchmark to the operator and wish to test it, you can add them by doing the following:

**1. Create your benchmark directory and test cases**

---

Create your benchmark directory inside `e2e/benchmarks` and add all of your test cases there.

>If you have any dependent kubernetes resources, you can create a `resources` subdir and add any raw Kubernetes YAML Manifests there. The framework will orchestrate setup/teardown of those resources automatically.

**2. Add your test module**

---

Create your test module by adding a file called `test_$BENCHMARK.py` under `e2e/tests`. The module should have a class that looks like this, replacing instances of `mybench/MyBench` with your benchmark name:

```python
from pytest import mark
from models.test_base import TestBase, default_timeout


@mark.mybench
class TestMyBench(TestBase):
    workload = "mybench"

    @mark.timeout(default_timeout)
    def test_mybench(self, run):
        self.run_and_check_benchmark(run)

```

**3. Add your benchmark to pytest.ini**

---

Finally, you can add your benchmark with a description to the `pytest.ini` file at the root of the project. This *must* be the same value that you marked your class with in your test module. 

### Advanced Usage

**Test Options**

---

There are specific test options surfaced up through the `TestBase` class that is inherited by the templated test case. 

* `workload: string`: Defines the name of the benchmark workload to be ran, which should map to the directory name under `e2e/benchmarks`
* `indices: list` : A list of elasticsearch indices to check against for data. If not supplied metadata collection is turned off and ES is not checked.
* `inject_cli_args: bool, Default: True`: Turns off injection of CLI arguments such as the ElasticSearch server. 
* `check_es: bool, Default: True`: This turns off the check against ElasticSearch. Metadata collection will still be on if ES CLI Args are supplied. 
* `benchmark_needs_prometheus, Default: False`: This is used if the benchmark under test requires the prometheus token supplied through the CLI arg `--prom-token`. 


**Custom setup/teardown methods**

---

In some benchmarks, it may be necessary to add more complex setup/teardown logic than what is provided by the framework. In order to do so, you can implement the `setup_method` and `teardown_method` methods in your class like so:


```python
from pytest import mark
from models.test_base import TestBase, default_timeout

@mark.mybench
class TestMyBench(TestBase):
    workload = "mybench"

    def setup_method(self, method):
        super().setup_method(method)
        # Put your custom code here, after calling super

    def teardown_method(self, method):
        # Put your custom code here, before calling super
        super().teardown_method(method)


    @mark.timeout(default_timeout)
    def test_mybench(self, run):
        self.run_and_check_benchmark(run)

```

**Using the helpers**

---

There are helpers injected into every test case inheriting the `TestBase` class. They are surfaced as a class variable called `self.helpers` which gives access to all functions defined the `Helper` class at `e2e/tests/conftest.py`