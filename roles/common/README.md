# Common Role
The common role contains tasks and templates that can be reused in a library fashion
across the other roles via `include_role` or `imort_role` functionality. You can 
include a particular file from the `tasks` directory with:

```yaml
- include_role:
    name: common
    tasks_from: task_file.yml
```

## enumeration_by_pattern.yml
The use case for this file is to take a source list and create a new enumeration
list of integers representing index values of the source list up to its length
based on a selected pattern.

Assume you have a source list called `rainbow`, with each color representing a list
of possible "targets" for a benchmark workload.

```yaml
- set_fact:
    rainbow: ['red', 'orange', 'yellow', 'green', 'blue', 'indigo', 'violet']
```

This list could be very long, with perhaps hundreds of entries. What you want to
do is ramp up your workload with increasing parallelism in each loop of execution.
With a short list, maybe you want to linearly increase the parallelism by 1
target with each loop. The pattern in this case is referred to as "by1" and is
provided as the `enumeration_pattern` variable.

```yaml
- set_fact:
    enumeration_list: "{{ rainbow }}"

- set_fact:
    enumeration_pattern: 'by1'
```

With these facts set in your playbook, you can then include the tasks from this
common role.

```yaml
- include_role:
    name: common
    tasks_from: enumeration_by_pattern.yml
```

The resulting output will be a new variable `enumeration` with a list of integers
representing a "count" of the source list items by the `enumeration_pattern`, in
this case `by1`.

```yaml
[1, 2, 3, 4, 5, 6, 7]
```

Note that the default is to one-base the counts, but this can be overridden
with `enumeration_zero_base: true`.

With the same source list but using `enumeration_pattern: 'by2'`, you get a list
in `enumeration` representing every-other item. In the scenario provided, this
would mean linear parallelism scaling but with half as many test cycles.

```yaml
[1, 3, 5, 7]
```

Choosing `enumeration_pattern: 'doubling'` creates an exponential doubling pattern
up to the highest value that does not exceed the source list length.

```yaml
[1, 2, 4]
```

The `doubling` pattern can be very useful where the source list is lengthy,
significantly reducing the number of total benchmark test cycles. If the source
list had a length of 100 items, for instance, you `enumeration` list would help
you choose to run only 7 test cycles, with the obvious caveat that in this case
the highest value in the 'enumeration' list is quite a bit below the source
list length.

```yaml
[1, 2, 4, 8, 16, 32, 64]
```

The final `enumeration_pattern: 'all'` option allows you to choose to run
simply one test cycle with the `enumeration` count equaling the source list
length (using the rainbow list again as the example).

```yaml
[7]
```
