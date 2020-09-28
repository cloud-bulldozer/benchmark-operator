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
If you do not do this, ripsaw will timeout waiting for cache dropper pods to deploy.


# implementation notes

kernel cache dropping is done by a daemonset run on nodes with the above label.   See roles/kernel_cache_drop
for details on how this is done.  Each pod started by this daemonset is running a CherryPy web service that
responds to a GET URL by dropping kernel cache using equivalent of shell commnand:

```
sync 
echo 3 > /proc/sys/vm/drop_caches
```

The sync is required because the kernel cannot drop cache on dirty pages.  
A logfile named /tmp/dropcache.log is visible on every cache dropper pod so you can see what it's doing

