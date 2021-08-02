from ripsaw.commands import operator

class TestOperatorCommands():
    def test_operator_commands(self, kind_kubeconfig, cluster, benchmark_namespace):
        operator.install(kubeconfig=kind_kubeconfig)
        pods = cluster.get_pods(label_selector="control-plane=controller-manager", namespace="benchmark-operator")
        assert len(pods.items) == 1
        assert pods.items[0].status.phase == "Running"
        operator.delete(kubeconfig=kind_kubeconfig)
        pods = cluster.get_pods(label_selector="control-plane=controller-manager", namespace="benchmark-operator")
        assert len(pods.items) == 0
    