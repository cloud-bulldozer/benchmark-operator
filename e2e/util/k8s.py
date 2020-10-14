from kubernetes import client, config, watch, utils
import json
from e2e.util.decorators import timeout
import time
import yaml
from e2e.util.exceptions import BenchmarkFailedError


class Cluster:
    def __init__(self):
        config.load_kube_config()
        self.api_client = client.ApiClient()
        self.core_client = client.CoreV1Api() 
        self.batch_client = client.BatchV1Api()
        self.crd_client = client.CustomObjectsApi()


    # Get Functions

    def get_pods_by_app(self, app, namespace): 
        label_selector=f"app={app}"
        return self.core_client.list_namespaced_pod(namespace, label_selector=label_selector, watch=False)

    def get_jobs_by_app(self, app, namespace): 
        label_selector=f"app={app}"
        return self.batch_client.list_namespaced_job(namespace, label_selector=label_selector, watch=False)
    
    def get_benchmark(self, name, namespace):
        return self.crd_client.get_namespaced_custom_object(
            group="ripsaw.cloudbulldozer.io",
            version="v1alpha1",
            namespace=namespace,
            plural="benchmarks",
            name=name
        )
    
    # Waiters

    @timeout(seconds=300)
    def wait_for_pods_by_app(self, app, namespace):
        waiting_for_pods = True
        while waiting_for_pods:
            pods = self.get_pods_by_app(app, namespace).items
            [ print(f"{pod.metadata.namespace}\t{pod.metadata.name}\t{pod.status.phase}") for pod in pods ]
            waiting_for_pods = (any([ pod.status.phase != "Running" for pod in pods]))
            time.sleep(3)

    @timeout(seconds=300)
    def wait_for_jobs_by_app(self, app, namespace):
        waiting_for_jobs = True
        while waiting_for_jobs:
            jobs = self.get_jobs_by_app(app, namespace).items
            [ print(f"{job.metadata.namespace}\t{job.metadata.name}\t{job.status.succeeded}") for job in jobs ]
            waiting_for_jobs = (any([ job.status.succeeded != 1 for job in jobs]))
            time.sleep(3)

    @timeout(seconds=500)
    def wait_for_benchmark(self, name, namespace, desired_state="Completed"): 
        waiting_for_benchmark = True
        while waiting_for_benchmark:
            benchmark = self.get_benchmark(name, namespace)
            bench_status = benchmark.get('status', {})
            uuid = bench_status.get('uuid', "Not Assigned Yet")
            current_state = bench_status.get('state', "")
            print(f"{benchmark['metadata']['namespace']}\t{benchmark['metadata']['name']}\t{uuid}\t{current_state}")
            if current_state == "Failed":
                raise BenchmarkFailedError(benchmark['metadata']['name'], benchmark['status']['uuid'])

            waiting_for_benchmark = (current_state != desired_state)
            time.sleep(3)
        print(f"{benchmark['metadata']['name']} with uuid {uuid} has reached the desired state {desired_state}")


    # Create Functions
    def create_benchmark(self, benchmark):
        self.crd_client.create_namespaced_custom_object(
            group="ripsaw.cloudbulldozer.io",
            version="v1alpha1",
            namespace=benchmark['metadata']['namespace'],
            plural="benchmarks",
            body=benchmark
        )
        try:
            self.wait_for_benchmark(benchmark['metadata']['name'], benchmark['metadata']['namespace'], desired_state="Running")
        except BenchmarkFailedError:
            print("error, benchmark failed")
        finally: 
            return self.get_benchmark_metadata(benchmark['metadata']['name'], benchmark['metadata']['namespace'])
    
    def get_benchmark_metadata(self, benchmark_name, benchmark_namespace):
        benchmark = self.get_benchmark(benchmark_name, benchmark_namespace)
        return {
            'name': benchmark['metadata']['name'],
            'namespace': benchmark['metadata']['namespace'],
            'uuid': benchmark['status']['uuid'],
            'suuid': benchmark['status']['suuid'],
            'related_job': f"{benchmark['spec']['workload']['name']}-{benchmark['status']['suuid']}",
            'status': benchmark['status']['state']
        }   
    
