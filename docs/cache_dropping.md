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
is done using these CR fields in the workload args section:

```
drop_cache_kernel: true
```

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
- fs-drift

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
drop before each sample is run.   The environment variables are:

- KCACHE_DROP_PORT_NUM - default of var kernel_cache_drop_svc_port should be fine
- kcache_drop_pod_ips - ansible var is already filled in by the cache dropper role

