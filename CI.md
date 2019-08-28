# CI

* [CI Framework](#ci-framework)
* [Requirements](#requirements)
* [Lifecycle of a CI test](#lifecycle-of-a-ci-test)
* [The Test Script](#the-test-script)
* [Adding New Tests](#adding-new-tests)

## CI Framework

The CI testing framework is built upon Ansible. It utilizes reusable roles
and tests to obtain the pass/fail of a PR.


## Requirements

The following is required to run the CI test scripts:
- [Ansible](https://docs.ansible.com/ansible/latest/index.html) 2.7 or greater 
- The ability to run the k8s module (see [module requirements](https://docs.ansible.com/ansible/latest/modules/k8s_module.html))
- [parallel](https://www.gnu.org/software/parallel/)


## Lifecycle of a CI test

To best understand the CI environment it is easiest to follow an example PR.

1) Say PR #111 gets submitted
2) Once it is tagged with "ok to test" the CI environment should add it to
its queue for each of the tested environments (minikube, minishift, kni, etc).
3) Once the test kicks off it launches the test.sh script on the appropriate
environment.
4) The test.sh script does some configuration and general setup/taredown for
the test as well as kicks off the execution. See [The Test Script](#the-test-script) section 
for details.
5) Once complete, the testing results are placed in Jenkins and Gitub
6) The Github results will include pass/fails for each workload test as well as
additional information around runtime, amount of attempts it took to pass, and
any failure information we can provide if applicable.


## The Test Script

The test.sh script kicks off the testing in the CI environment

It can be broken into three sections: Prep, Execution, Cleanup

**PREP**

During the Prep phase the files are configured for a new CI test run.

This includes:
- Updating the operator image (**note:** the command will likely not work on your
local machine since it pushes to a privleged repo. Change this to your own or delete
it if not needed)
- Creating individual directories for each test
- Setting the namespace for each individual test to my-ripsaw-test-[TEST_NAME]
- Setting the ripsaw directory to the current working directory for each test
(**note:** if running tests locally or outside of the test.sh script, you will need
to set ripsaw_dir in tests/group_vars/all.yml to your ripsaw directory)


**Execution**

The Execution phase is, as it sounds, meant to kick off the test of each workload.

These tests are run in parallel via
```parallel -n 1 -a tests/my_tests -P $max_concurrent ./run_test.sh```

Where max_concurrent is the maximum number of concurrent tests to run.
Please keep this in mind when writing your test case as it may impact running times
of the test. The run_test.sh script essentially runs the playbook with the tags
for each individual test. It attempts 3 retries if a test fails before marking
the test as failed.

**Cleanup**

Once all the tests have been run we enter the cleanup phase. As the name implies,
during this phase we cleanup the environment. Additionally, this stage will complete
the testing files and set them up for being pushed to Jenkins and Github.


**Important Notes:**

- The CI test runs multiple tests at once from the same PR. Meaning it may
run a test of smallfile, fiod and uperf all at the same time.
To manage this, the tests are spawned into their own namespaces. This is done
with a simple sed replace line searching for my-ripsaw and replacing it with
my-ripsaw-test-[TEST_NAME]. This should be kept in mind when creating new tests

## Adding New Tests

Reminder that the CI test is not meant to be a long running test. It is meant to
ensure functionality and not to gather performance metrics.

**Anatomy of the Ansible testing Framework**

The Ansible testing files are all located in the tests directory. The main playbook
is run_test.yml. It can be broken up to two sections. Tests with benchmarks that 
support reconciliation (**preferred**)and tests that do not.

If a test supports reconciliation it is run through the launch_test role. This role
will create the namespace, launch the operator, kick off the benchmark, wait for it
to complete and then check the pod logs for a string to verify a successful test.

Looking at the iperf3 test, it is defined with a test_iperf3 tag and defines a 
variable file that is to be used in the test.

The task definition in run_test.yml
```
- name: Run test_iperf3
      import_role:
        name: launch_test
        vars_from: iperf3.yml
      tags: [ test_iperf3, all ]
```

The iperf3.yml variable file is located in tests/roles/launch_test/vars/ and
contains varible definitions to be used in testing.
```
cr: /tests/test_crs/valid_iperf3.yaml
namespace: my-ripsaw
test_name: iperf3-bench-client
test_retries: 20
test_delay: 10
test_check: "iperf Done"
```

The variables can be described such as:

- **cr** - The path to the custom resource file for the benchmark
- **namespace** - The namespace to be used for the benchmark (this should normally
be my-ripsaw)
- **test_name** - This is the pod label as defined in the workload as app=X that will be 
- **test_retries** - The number of retries to preform while waiting for the benchmark
to complete
- **test_delay** - The amount of time to wait between retries of checking for completion
of the benchmark
- **test_check** - The string that will be searched for in the logs to asses pass/failure
of the test


If a test does not support reconciliation, then the test is defined in its own role

Looking at pgbench for example. We define the test in run_test.yml as:
```
    - name: Run test_pgbench
      import_role:
        name: test_pgbench
      tags: [ test_pgbench, all ]
```

test_pgbench corresponds with the test_pgbench role defined in tests/roles/

The definition of said role will vary depending on the test at hand however there
are a few helper roles that can be used to move things along.

The **launch_test** role simply launches the namespace, operator, and applys a given
cr. It does not wait for any completion however it does return a variable (my_test)
which is what is returned after applying the cr.

The **common** role contains multiple commonly used functions.
- **get_logs.yml** - Gets the logs of all pods in the defined namespace and prints
them using the debug function
- **deploy.yml** - Creates the namespace and deploys the ripsaw operator
- **delete_operator.yml** - Deletes all resources in the namespace as well as the
namespace itself
- **delete_namespace.yml** - Deletes the namespace without removing anything else
first

**Creating a new test**

When creating a new test it is easiest if the benchmark supports reconciliation.
If that is the case then you will need to add the test to tests/run_test.yml
with the appropriate lables and populate the variable file in tests/roles/launch_test/vars

If the test does not support reconciliation then copy an existing test role (such
as pgbench) and use that as an example to update for your test. Be aware that many of the
tests use the meta directory in the role for some pre-setup. Lastly, update the run_test.yml
with the appropriate role information and tagging.

**NOTE:** The namespace and working ripsaw directory are defined in 
tests/group_vars/all.yml. Please update this for your testing. During the test run
through test.sh or run_test.sh the ripsaw_dir gets replaced with its current working directory.
