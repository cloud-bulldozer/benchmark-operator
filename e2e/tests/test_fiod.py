from pytest import mark
from models.test_base import TestBase, default_timeout

@mark.fiod
class TestFiod(TestBase):
    workload = "fiod"
    indexes= [
        "ripsaw-fio-results",
        "ripsaw-fio-log", 
        "ripsaw-fio-analyzed-result"
    ]

    def setup_method(self, method):
        super().setup_method(method)
        kernel_patch = {
            "metadata": {
                "labels": {
                    "kernel-cache-dropper": "yes"
                }
            }
        }
        cluster = self.helpers.get_cluster()
        nodes = cluster.get_node_names('node-role.kubernetes.io/worker= ')
        [ cluster.patch_node(node, kernel_patch) for node in nodes ]

    def teardown_method(self, method):
        kernel_patch = {
            "metadata": {
                "labels": {
                    "kernel-cache-dropper": "no"
                }
            }
        }
        cluster = self.helpers.get_cluster()
        nodes = cluster.get_node_names('node-role.kubernetes.io/worker= ')
        [ cluster.patch_node(node, kernel_patch) for node in nodes ]
        super().teardown_method(method)


    @mark.timeout(default_timeout)
    def test_fiod(self, run):
        self.run_and_check_benchmark(run)