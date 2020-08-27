#!/usr/bin/python3
# wait_for_daemonset.py -
# wait until all pods are in Running state for specified DaemonSet
# see usage() for input params

from kubernetes import client, config
from sys import argv, exit
import time

NOTOK=1
# may have to adjust this based on number of pods
poll_interval = 2.0

def usage(msg):
    print('ERROR: %s' % msg)
    print('usage: wait_for_daemonset.py timeout namespace node-label pod-app')
    exit(NOTOK)

# parse command line

if len(argv) < 3:
    usage('too few parameters')

timeout_str = argv[1]
ns = argv[2]
label = argv[3]

# show 'em what we parsed

print('timeout if pods not seen in %s sec' % timeout_str)
print('namespace: %s' % ns)
print('node label: %s' % label)

timeout = int(timeout_str)
if timeout <= poll_interval:
    usage('timeout %d must be greater than poll interval %d' % 
            (timeout, poll_interval))

# wait for pods

config.load_kube_config()
v1 = client.CoreV1Api()

nodes = v1.list_node().items
matching_nodes = 0
for n in nodes:
    try:
        v = n.metadata.labels[label]
        matching_nodes += 1
    except KeyError:
        pass

print('expecting %d nodes to have this pod' % matching_nodes)
if matching_nodes == 0:
    usage('at least 1 node must have the %s label')

start_time = time.time()
matching_pods = 0
generate_name = label + '-'

while True:
    time.sleep(poll_interval)
    now_time = time.time()
    delta_time = now_time - start_time
    if delta_time > timeout:
        break

    print("Listing pods in namespace %s with their IPs:" % ns)
    ret = v1.list_pod_for_all_namespaces(watch=False)
    matching_pods = 0
    for i in ret.items:
        if i.metadata.namespace == ns:
            print("%s\t%s\t%s" % (i.status.pod_ip, i.metadata.namespace, i.metadata.name))
            if i.metadata.generate_name == generate_name:
                if i.status.phase == 'Running':
                    matching_pods += 1
    if matching_pods >= matching_nodes:
        break

if delta_time > timeout:
    usage('timeout waiting for pods to reach running state')

if matching_pods != matching_nodes:
    usage('expected %d pods, found %d pods' % (matching_nodes, matching_pods))

