# FIO Benchmark

[FIO](https://github.com/axboe/fio) or Flexible IO Tester is a tool that would be able to simulate a given I/O workload without resorting to writing a tailored test case again and again.

FIO spawns a number of threads or processes doing a particular type of I/O action as specified by the user. FIO takes a number of global parameters, each inherited by the thread unless otherwise parameters given to them overriding that setting is given. The typical use of FIO is to write a job file matching the I/O load one wants to simulate.

## Running FIO Benchmark

Once the operator has been installed following the instructions, one needs to modify the [cr.yaml](../resources/crds/benchmark_v1alpha1_fio_cr.yaml) to run either sequential, random or custom workload. For custom workload one can provide URL of http server where FIO job file is present.

The FIO section in [cr.yaml](../resources/crds/benchmark_v1alpha1_fio_cr.yaml) would look like this.

```yaml
apiVersion: benchmark.example.com/v1alpha1
kind: Benchmark
metadata:
  name: example-benchmark
spec:
  fio:
    # To disable fio, set clients to 0
    job: seq # either of  seq, rand or custom
    clients: 2 # specify number of clients on which FIO should run
    jobname: seq # either of seq, rand or custom
    get_url: # Job is custom, provide URL of job here
    bs: 64k # provide only if job is seq or rand
    iodepth: 4 # provide only if job is seq or rand
    runtime: 60 # provide only if job is seq or rand
    numjobs: 2 # provide only if job is seq or rand
    filesize: 2 # File size in GB,  provide only if job is seq or rand
    storageclass: rook-ceph-block # Provide if PV is needed
    storagesize: 30Gi # Provide if PV is needed
```

Note: Please ensure to set 0 for other workloads if editing the [cr.yaml](../resources/crds/benchmark_v1alpha1_fio_cr.yaml) file otherwise desired workload won't be executed. If storage class is defined we can provide persistent volume (PV) to the POD where FIO test will be executed.

Once done creating/editing the resource file, one can run it by:

```bash
# kubectl apply -f resources/crds/benchmark_v1alpha1_fio_cr.yaml # if edited the original one
# kubectl apply -f <path_to_file> # if created a new cr file
```

Deploying the above(assuming clients set to 2) would result in

```bash
kubectl get pods
NAME                                       READY     STATUS    RESTARTS   AGE
benchmark-operator-54bf9f4c44-llzwp        1/1       Running   0          1m
example-benchmark-fio-client-1-benchmark   1/1       Running   0          22s
example-benchmark-fio-client-2-benchmark   1/1       Running   0          22s
```

Since we have storageclass and storagesize defined in [cr.yaml](../resources/crds/benchmark_v1alpha1_fio_cr.yaml) file, the corresponding status of persitent volume is seen like this:

```bash
kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM              STORAGECLASS      REASON    AGE
pvc-0f20b50d-5c57-11e9-b95c-d4ae528b96c1   30Gi       RWO            Delete           Bound     benchmark/claim1   rook-ceph-block             19s
pvc-0f9ee947-5c57-11e9-b95c-d4ae528b96c1   30Gi       RWO            Delete           Bound     benchmark/claim2   rook-ceph-block             18s
```

To see the output of the run one has to run `kubectl logs <client>`. This is shown below:

```bash
 kubectl logs example-benchmark-fio-client-2-benchmark -f
[global]
name=seq
directory=/mnt/pvc
ioengine=sync
bs=64k
iodepth=4
direct=0
create_on_open=1
time_based=1
runtime=60
clocksource=clock_gettime
ramp_time=10

[write]
rw=write
size=2g
write_bw_log=fio
write_iops_log=fio
write_lat_log=fio
write_hist_log=fio
numjobs=2
per_job_logs=1
log_avg_msec=60000
log_hist_msec=60000
startdelay=20
filename_format=f.\$jobnum.\$filenum
end_fsync=1

[read]
rw=read
size=2g
write_bw_log=fio
write_iops_log=fio
write_lat_log=fio
write_hist_log=fio
numjobs=2
per_job_logs=1
log_avg_msec=60000
log_hist_msec=60000
startdelay=60
filename_format=f.\$jobnum.\$filenum


[readwrite]
rw=rw
size=2g
write_bw_log=fio
write_iops_log=fio
write_lat_log=fio
write_hist_log=fio
numjobs=2
per_job_logs=1
log_avg_msec=60000
log_hist_msec=60000
startdelay=120
filename_format=f.\$jobnum.\$filenum
write: (g=0): rw=write, bs=(R) 64.0KiB-64.0KiB, (W) 64.0KiB-64.0KiB, (T) 64.0KiB-64.0KiB, ioengine=sync, iodepth=4
...
read: (g=0): rw=read, bs=(R) 64.0KiB-64.0KiB, (W) 64.0KiB-64.0KiB, (T) 64.0KiB-64.0KiB, ioengine=sync, iodepth=4
...
readwrite: (g=0): rw=rw, bs=(R) 64.0KiB-64.0KiB, (W) 64.0KiB-64.0KiB, (T) 64.0KiB-64.0KiB, ioengine=sync, iodepth=4
...
fio-3.12
Starting 6 processes

write: (groupid=0, jobs=1): err= 0: pid=12: Thu Apr 11 12:46:29 2019
  write: IOPS=226, BW=14.2MiB/s (14.8MB/s)(992MiB/70062msec)
    clat (nsec): min=0, max=14173M, avg=4086746.44, stdev=125211870.21
     lat (nsec): min=0, max=14173M, avg=4088394.03, stdev=125211869.15
    clat percentiles (usec):
     |  1.00th=[     30],  5.00th=[     37], 10.00th=[     42],
     | 20.00th=[     52], 30.00th=[     68], 40.00th=[     85],
     | 50.00th=[    105], 60.00th=[    165], 70.00th=[    717],
     | 80.00th=[   3687], 90.00th=[   8848], 95.00th=[  12911],
     | 99.00th=[  28443], 99.50th=[  40633], 99.90th=[  63177],
     | 99.95th=[  86508], 99.99th=[5603591]
   bw (  KiB/s): min=    0, max=16856, per=58.82%, avg=16856.00, stdev= 0.00, samples=1
   iops        : min=    0, max=  263, avg=263.00, stdev= 0.00, samples=1
  lat (usec)   : 50=18.34%, 100=29.99%, 250=13.73%, 500=3.42%, 750=4.80%
  lat (usec)   : 1000=1.41%
  lat (msec)   : 2=1.92%, 4=7.97%, 10=9.94%, 20=6.65%, 50=1.58%
  lat (msec)   : 100=0.22%, 250=0.01%
  cpu          : usr=0.20%, sys=1.29%, ctx=22780, majf=0, minf=44
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,15870,0,1 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=4
write: (groupid=0, jobs=1): err= 0: pid=13: Thu Apr 11 12:46:29 2019
  write: IOPS=75, BW=4848KiB/s (4964kB/s)(328MiB/69241msec)
    clat (nsec): min=0, max=2905.4M, avg=11438998.52, stdev=71301391.72
     lat (nsec): min=0, max=2905.4M, avg=11440866.61, stdev=71301444.55
    clat percentiles (usec):
     |  1.00th=[     32],  5.00th=[     42], 10.00th=[     48],
     | 20.00th=[     62], 30.00th=[     84], 40.00th=[    103],
     | 50.00th=[    147], 60.00th=[    506], 70.00th=[   2573],
     | 80.00th=[  11338], 90.00th=[  25035], 95.00th=[  45876],
     | 99.00th=[ 137364], 99.50th=[ 233833], 99.90th=[ 675283],
     | 99.95th=[2231370], 99.99th=[2902459]
   bw (  KiB/s): min=    0, max= 5593, per=19.52%, avg=5593.00, stdev= 0.00, samples=1
   iops        : min=    0, max=   87, avg=87.00, stdev= 0.00, samples=1
  lat (usec)   : 50=11.71%, 100=27.26%, 250=17.16%, 500=3.74%, 750=4.77%
  lat (usec)   : 1000=2.00%
  lat (msec)   : 2=2.63%, 4=2.42%, 10=6.81%, 20=9.27%, 50=7.82%
  lat (msec)   : 100=2.67%, 250=1.28%, 500=0.32%, 750=0.06%, 1000=0.02%
  cpu          : usr=0.08%, sys=0.58%, ctx=13981, majf=0, minf=63
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5245,0,1 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=4
read: (groupid=0, jobs=1): err= 0: pid=14: Thu Apr 11 12:46:29 2019
  read: IOPS=377, BW=23.6MiB/s (24.8MB/s)(1542MiB/65312msec)
    clat (nsec): min=0, max=14173M, avg=2640261.75, stdev=100441081.06
     lat (nsec): min=0, max=14173M, avg=2641039.07, stdev=100441080.35
    clat percentiles (usec):
     |  1.00th=[     12],  5.00th=[     32], 10.00th=[     36],
     | 20.00th=[     40], 30.00th=[     44], 40.00th=[     50],
     | 50.00th=[     62], 60.00th=[     85], 70.00th=[    124],
     | 80.00th=[    644], 90.00th=[   4883], 95.00th=[  10421],
     | 99.00th=[  20317], 99.50th=[  31065], 99.90th=[  53216],
     | 99.95th=[  63177], 99.99th=[3841983]
   bw (  KiB/s): min=    0, max=26285, per=62.15%, avg=26285.00, stdev= 0.00, samples=1
   iops        : min=    0, max=  410, avg=410.00, stdev= 0.00, samples=1
  lat (usec)   : 20=2.69%, 50=38.25%, 100=23.95%, 250=10.24%, 500=2.89%
  lat (usec)   : 750=2.54%, 1000=0.88%
  lat (msec)   : 2=1.24%, 4=5.26%, 10=6.58%, 20=4.43%, 50=0.91%
  lat (msec)   : 100=0.10%, 250=0.01%, 500=0.01%
  cpu          : usr=0.23%, sys=1.75%, ctx=29768, majf=0, minf=74
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=24677,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=4
read: (groupid=0, jobs=1): err= 0: pid=15: Thu Apr 11 12:46:29 2019
  read: IOPS=133, BW=8531KiB/s (8736kB/s)(500MiB/60017msec)
    clat (nsec): min=0, max=2373.7M, avg=7494788.90, stdev=54104843.84
     lat (nsec): min=0, max=2373.7M, avg=7495651.89, stdev=54104875.54
    clat percentiles (usec):
     |  1.00th=[     14],  5.00th=[     37], 10.00th=[     40],
     | 20.00th=[     46], 30.00th=[     53], 40.00th=[     65],
     | 50.00th=[     86], 60.00th=[    117], 70.00th=[    351],
     | 80.00th=[   3949], 90.00th=[  16319], 95.00th=[  33817],
     | 99.00th=[ 103285], 99.50th=[ 160433], 99.90th=[ 530580],
     | 99.95th=[ 708838], 99.99th=[2365588]
   bw (  KiB/s): min=    0, max= 8532, per=20.17%, avg=8532.00, stdev= 0.00, samples=1
   iops        : min=    0, max=  133, avg=133.00, stdev= 0.00, samples=1
  lat (usec)   : 20=1.76%, 50=24.40%, 100=28.96%, 250=13.91%, 500=3.14%
  lat (usec)   : 750=2.95%, 1000=1.40%
  lat (msec)   : 2=1.74%, 4=1.78%, 10=5.10%, 20=6.80%, 50=5.24%
  lat (msec)   : 100=1.69%, 250=0.86%, 500=0.16%, 750=0.06%
  cpu          : usr=0.10%, sys=0.72%, ctx=10203, majf=0, minf=46
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=8000,0,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=4
readwrite: (groupid=0, jobs=1): err= 0: pid=16: Thu Apr 11 12:46:29 2019
  read: IOPS=120, BW=7713KiB/s (7898kB/s)(492MiB/65312msec)
    clat (nsec): min=0, max=1103.7M, avg=1516074.62, stdev=13638586.90
     lat (nsec): min=0, max=1103.7M, avg=1516872.69, stdev=13638581.19
    clat percentiles (usec):
     |  1.00th=[     16],  5.00th=[     18], 10.00th=[     20],
     | 20.00th=[     26], 30.00th=[     49], 40.00th=[     58],
     | 50.00th=[     66], 60.00th=[     83], 70.00th=[    114],
     | 80.00th=[    465], 90.00th=[   3851], 95.00th=[   9372],
     | 99.00th=[  18482], 99.50th=[  25560], 99.90th=[  50594],
     | 99.95th=[  60031], 99.99th=[1098908]
   bw (  KiB/s): min=    0, max= 8384, per=19.83%, avg=8384.00, stdev= 0.00, samples=1
   iops        : min=    0, max=  131, avg=131.00, stdev= 0.00, samples=1
  write: IOPS=118, BW=7606KiB/s (7789kB/s)(485MiB/65312msec)
    clat (nsec): min=0, max=14173M, avg=6861539.03, stdev=193488588.88
     lat (nsec): min=0, max=14173M, avg=6863180.92, stdev=193488585.31
    clat percentiles (usec):
     |  1.00th=[      24],  5.00th=[      31], 10.00th=[      40],
     | 20.00th=[      71], 30.00th=[      84], 40.00th=[     121],
     | 50.00th=[     461], 60.00th=[     930], 70.00th=[    3392],
     | 80.00th=[    5932], 90.00th=[   11338], 95.00th=[   16319],
     | 99.00th=[   38011], 99.50th=[   49546], 99.90th=[   86508],
     | 99.95th=[  219153], 99.99th=[14159971]
   bw (  KiB/s): min=    0, max= 8267, per=28.85%, avg=8267.00, stdev= 0.00, samples=1
   iops        : min=    0, max=  129, avg=129.00, stdev= 0.00, samples=1
  lat (usec)   : 20=5.76%, 50=16.00%, 100=29.42%, 250=11.81%, 500=3.34%
  lat (usec)   : 750=4.70%, 1000=1.39%
  lat (msec)   : 2=1.84%, 4=7.57%, 10=9.58%, 20=6.52%, 50=1.78%
  lat (msec)   : 100=0.23%, 250=0.03%, 500=0.01%
  cpu          : usr=0.17%, sys=1.29%, ctx=20814, majf=0, minf=55
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=7871,7762,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=4
readwrite: (groupid=0, jobs=1): err= 0: pid=17: Thu Apr 11 12:46:29 2019
  read: IOPS=43, BW=2783KiB/s (2849kB/s)(163MiB/60007msec)
    clat (nsec): min=0, max=666881k, avg=6589474.75, stdev=27267603.06
     lat (nsec): min=0, max=666882k, avg=6590305.16, stdev=27267616.19
    clat percentiles (usec):
     |  1.00th=[    17],  5.00th=[    20], 10.00th=[    23], 20.00th=[    46],
     | 30.00th=[    58], 40.00th=[    68], 50.00th=[    81], 60.00th=[   112],
     | 70.00th=[   176], 80.00th=[  1909], 90.00th=[ 15795], 95.00th=[ 34866],
     | 99.00th=[112722], 99.50th=[162530], 99.90th=[367002], 99.95th=[367002],
     | 99.99th=[666895]
   bw (  KiB/s): min=    0, max= 2781, per=6.58%, avg=2781.00, stdev= 0.00, samples=1
   iops        : min=    0, max=   43, avg=43.00, stdev= 0.00, samples=1
  write: IOPS=41, BW=2662KiB/s (2726kB/s)(156MiB/60007msec)
    clat (nsec): min=0, max=2533.8M, avg=17136044.03, stdev=96777341.63
     lat (nsec): min=0, max=2533.8M, avg=17137772.76, stdev=96777417.55
    clat percentiles (usec):
     |  1.00th=[     25],  5.00th=[     38], 10.00th=[     63],
     | 20.00th=[     83], 30.00th=[    109], 40.00th=[    188],
     | 50.00th=[    603], 60.00th=[   2507], 70.00th=[   9634],
     | 80.00th=[  16909], 90.00th=[  34866], 95.00th=[  58983],
     | 99.00th=[ 214959], 99.50th=[ 291505], 99.90th=[2264925],
     | 99.95th=[2365588], 99.99th=[2533360]
   bw (  KiB/s): min=    0, max= 2662, per=9.29%, avg=2662.00, stdev= 0.00, samples=1
   iops        : min=    0, max=   41, avg=41.00, stdev= 0.00, samples=1
  lat (usec)   : 20=3.60%, 50=11.99%, 100=26.78%, 250=15.06%, 500=3.37%
  lat (usec)   : 750=4.54%, 1000=2.19%
  lat (msec)   : 2=2.29%, 4=2.53%, 10=6.37%, 20=8.89%, 50=7.68%
  lat (msec)   : 100=2.80%, 250=1.49%, 500=0.20%, 750=0.12%, 1000=0.02%
  cpu          : usr=0.05%, sys=0.53%, ctx=7476, majf=0, minf=29
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=2609,2496,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=4

Run status group 0 (all jobs):
   READ: bw=41.3MiB/s (43.3MB/s), 2783KiB/s-23.6MiB/s (2849kB/s-24.8MB/s), io=2697MiB (2828MB), run=60007-65312msec
  WRITE: bw=27.0MiB/s (29.3MB/s), 2662KiB/s-14.2MiB/s (2726kB/s-14.8MB/s), io=1961MiB (2056MB), run=60007-70062msec

Disk stats (read/write):
  rbd0: ios=8181/53908, merge=524/35828, ticks=140978/43859805, in_queue=32127940, util=99.60%
```
