This page describes how to use cache-dropping features of benchmark-operator.   
This feature is totally optional and if you do not specify it in the CR, then it will not happen.

# why drop cache

Cache-dropping prevents previous state of system from affecting performance results, and this helps you
to achieve repeatable, accurate results with low variance.

Caching is an important part of any system's performance, and it is of course desirable in some cases 
to explicitly make use of caching.   However, this cache-dropping feature does not prevent testing of
caching performance - if you run a long enough test for the cache to "warm up", you can do this even
with cache-dropping enabled, since cache-dropping only happens before each sample, not in the middle of
a sample.

If you want to ensure that caching will not happen during your test, you can create a data set that
is much bigger than the amount of memory available for caching, and use a uniform random access pattern.

# how to drop cache

There are different types of caching that occur in the system 

- kernel buffer caching
- (Ceph OCS) OSD caching (not yet supported fully)

you can control which type of cache dropping
is done using one or both of these CR fields in the workload args section:

```
drop_cache_kernel: true
drop_cache_rook_ceph: true
```

## how to drop kernel cache 

For this to work, you must **label** the nodes that you want to drop kernel cache, for example:

```
# kubectl label node minikube kernel-cache-dropper=yes
```
If you do not do this, benchmark-operator will reject the benchmark with an error to the effect that
none of the cluster nodes have this label. This label controls where kernel cache is dropped.

There will be a short delay after kernel cache is dropped in order to allow the system to recover 
some key cache contents before stressing it with a workload.  This is controllable via the CACHE_RELOAD_TIME
env. var. and defaults to 10 sec.

You must also execute this command before running a benchmark.

```
oc create -f ripsaw.l/resources/kernel-cache-drop-clusterrole.yaml
```

Lastly, the specific benchmark must support this feature.   
Benchmarks supported for kernel cache dropping at present are:

- fio
- smallfile

## how to drop Ceph OSD cache

For this to work with OpenShift Container Storage, you must do these steps once the benchmark-operator is running:
and the cache dropper pod, and enable benchmark-operator to see into the openshift-storage namespace.   
You can do this with:

```

# enable the benchmark operator to look for pods in the openshift-storage namespace
oc create -f roles/ceph_osd_cache_drop/ocs-cache-drop-clusterrole.yaml

# start the Ceph toolbox pod in openshift-storage namespace
oc patch OCSInitialization ocsinit -n openshift-storage --type json --patch \
  '[{ "op": "replace", "path": "/spec/enableCephTools", "value": true }]'

# start the OSD cache dropper pod in openshift-storage namespace
oc create -f roles/ceph_osd_cache_drop/rook_ceph_drop_cache_pod.yaml

# repeat until you see if the 2 pods are both running
oc -n openshift-storage get pod | awk '/tool/||/drop/'

```

when you see both of these pods in the running state, then you can use benchmark operator.   The reason that
you have to manually start these two pods running is that the benchmark-operator does not have authorization
to run them in the openshift-storage namespace and get access to the secrets needed to do this.

Benchmarks supported for Ceph OSD cache dropping are:

- fio
- smallfile

# implementation notes

For benchmark developers...

kernel cache dropping is done by a daemonset run on nodes with the above label.   See roles/kernel_cache_drop
for details on how this is done.  Each pod started by this daemonset is running a CherryPy web service that
responds to a GET URL by dropping kernel cache using equivalent of shell command:

```
sync 
echo 3 > /proc/sys/vm/drop_caches
```

The sync is required because the kernel cannot drop cache on dirty pages.  
A logfile named /tmp/dropcache.log is visible on every cache dropper pod so you can see what it's doing

The benchmark itself must pass environment variables to run_snafu.py in order for it to request a cache
drop before each sample is run.   Make sure only 1 of the workload pods requests cache dropping for each sample.
The environment variables are:

- KCACHE_DROP_PORT_NUM - default of var kernel_cache_drop_svc_port should be fine
- kcache_drop_pod_ips - ansible var is already filled in by the cache dropper role

For example, in your workload.yml.j2 where it creates the environment variables for the pod:

```
          - name: kcache_drop_pod_ips
            value: "{{ kcache_drop_pod_ips | default() }}"
          - name: KCACHE_DROP_PORT_NUM
            value: "{{ kernel_cache_drop_svc_port }}"
```

similarly, for Ceph OSD cache dropping, you must add this to one of your workload pods' environment variables:
```

{% if ceph_osd_cache_drop_pod_ip is defined %}
          - name: ceph_osd_cache_drop_pod_ip
            value: "{{ ceph_osd_cache_drop_pod_ip }}"
          - name: CEPH_CACHE_DROP_PORT_NUM
            value: "{{ ceph_cache_drop_svc_port }}"
{% endif %}

```
The ansible playbook for benchmark-operator will look up the ceph_osd_cache_drop_pod_ip IP address and fill in this var, 
all you have to do is pass it in.  See the ceph_osd_cache_drop ansible role for details.

