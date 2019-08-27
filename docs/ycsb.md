# YCSB

[YCSB](https://github.com/brianfrankcooper/YCSB) is a performance test kit for key-value and other cloud serving stores.

## Running YCSB

Given that you followed instructions to deploy operator,
you can modify [cr.yaml](../resources/crds/ripsaw_v1alpha1_ycsb_cr.yaml) to your needs.

YCSB is a workload that requires a database/key-value store to run workloads against and benchmark.

Your resource file may look like this:
```yaml
apiVersion: ripsaw.cloudbulldozer.io/v1alpha1
kind: Benchmark
metadata:
  name: ycsb-mongo-benchmark
  namespace: my-ripsaw
spec:
  clustername: myk8scluster
  workload:
    name: ycsb
    args:
      infra: mongodb
      driver: mongodb
      recordcount: 100
      operationcount: 100
      workloads:
        - workloada
        - workloadb
      options_load: '-p mongodb.url="mongodb://mongo/ycsb?"' #passed as is to ycsb when loading database
      options_run: '-p mongodb.url="mongodb://mongo/ycsb?" -threads 10 -target 100'
```

The following options in args are required:

`infra` is the database against which you're running mongodb

`driver` is the driver used to interact with database, you can choose from [YCSB Github](https://github.com/brianfrankcooper/YCSB)

`recordcount` number of records to be inserted into the database (insertcount defaults to recordcount).

`operationcount` number of operations to run against the database

`workload` is a list of workloads to run, you can read about the workloads at [YCSB workloads](https://github.com/brianfrankcooper/YCSB/wiki/Core-Workloads)
Note: We currently support running either workloade or workloadd( and not in the same list) as the last workload in the list.
      If you'd like to run both of them, then you'll have to apply the cr with workloadd/workloade as the last workload in the args.
      Then after it finishes running all workloads, you'll have to manually drop the database.
      Then create another CR with a different benchmark name with just the workloade/workloadd in the workload list that wasn't run previously.
Reason: Similar to reason provided by [YCSB documentation](https://github.com/brianfrankcooper/YCSB/wiki/Core-Workloads#running-the-workloads), we'd need to drop the database
        after running either of the workloadd/workloade. This would mean operator to have knowledge of interaction with the said DB, which was outside the scope of this operator.

`options_run` these are the options passed to ycsb binary while running the workload, this is where the target database and options are passed.
Please read YCSB documentation on the necessary args required for the particular database. And note, the url or API needs to be accessible from the ycsb pod.

The following options are optional:

`loaded` This can be optionally set to true, if you have already loaded the database.

`options_load` This needs to be set if `loaded` is not defined or set to false, and like in the case of `options_run` this needs to be configured properly,
so that the ycsb pod can access the API of database.

Once done creating/editing the resource file, you can run it by:

```bash
# kubectl apply -f resources/crds/ripsaw_v1alpha1_ycsb_cr.yaml # if edited the original one
# kubectl apply -f <path_to_file> # if created a new cr file
```
