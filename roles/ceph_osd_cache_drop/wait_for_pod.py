#!/usr/bin/python3
# wait_for_pod.py -
# wait until toolbox pod and web service pod is in Running state for specified deploy
# see usage() for input params

from kubernetes import client, config
from sys import argv, exit
import time

NOTOK = 1
# may have to adjust this based on number of pods
poll_interval = 2.0
ceph_osd_cache_drop_pod_name = 'ceph-osd-cache-drop'

def usage(msg):
    print('ERROR: %s' % msg)
    print('usage: wait_for_pod.py timeout namespace')
    exit(NOTOK)


# parse command line

if len(argv) < 3:
    usage('too few parameters')

timeout_str = argv[1]
ns = argv[2]

# show 'em what we parsed

print('timeout if pods not seen in %s sec' % timeout_str)
print('namespace: %s' % ns)

timeout = int(timeout_str)
if timeout <= poll_interval:
    usage('timeout %d must be greater than poll interval %d' %
          (timeout, poll_interval))

# wait for pods

# cannot do this from inside cluster pod: config.load_kube_config()
config.load_incluster_config()
v1 = client.CoreV1Api()

print('waiting for pod...')
start_time = time.time()
matching_pods = 0
generate_name = label + '-'

while True:
    time.sleep(poll_interval)
    now_time = time.time()
    delta_time = now_time - start_time
    if delta_time > timeout:
        break

    ret = v1.list_pod_for_all_namespaces(watch=False)
    matching_pods = 0
    for i in ret.items:
        if i.metadata.namespace == ns and \
           i.metadata.generate_name.__contains__ (ceph_osd_cache_drop_pod) and \
           i.status.phase == 'Running':
            matching_pods += 1
    if matching_pods >= 1:
        break

if delta_time > timeout:
    usage('timeout waiting for pods to reach running state')

if matching_pods != 1:
    usage('expected 1 pod, found %d pods' % matching_pods)
