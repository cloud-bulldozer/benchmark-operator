from kubernetes import client, config, watch
import json
from decorators import timeout
import time

class Cluster:
    def __init__(self):
        config.load_kube_config()
        self.client = client.CoreV1Api() 


    def get_pods_by_app(self, app, namespace): 
        label_selector=f"app={app}"
        return self.client.list_namespaced_pod(namespace, label_selector=label_selector, watch=False)
    
    @timeout(seconds=300)
    def wait_for_pods_by_app(self, app, namespace):
        waiting_for_pods = True
        while waiting_for_pods:
            pods = self.get_pods_by_app(app, namespace).items
            [ print(f"{pod.metadata.namespace}\t{pod.metadata.name}\t{pod.status.phase}") for pod in pods ]
            waiting_for_pods = (any([ pod.status.phase != "Running" for pod in pods]))
            time.sleep(3)




if __name__ == '__main__':
    cluster = Cluster()
    cluster.wait_for_pods_by_app("kube-burner-benchmark-266b269b", "my-ripsaw")