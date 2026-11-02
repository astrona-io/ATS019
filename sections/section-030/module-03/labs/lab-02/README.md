---
estimated_duration: 25m
---

# Fix A Failing Composition Found By Tracing

- **Slug:** ats-019-lab-030-03-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona hands-on lab, graded

The learner traces a `TeamEnvironment` that does not become `Ready`. The
Composition has two faults: the `service` resource names a ProviderConfig that
does not exist, and the `deployment` patch reads a misspelled request field
(`spec.replica`). The graders check the repaired Composition, the unchanged
request, the Deployment replicas, a real request from `shuttle` and that no
shortcut was used.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-03/labs/lab-02
astrona submit -c sections/section-030/module-03/labs/lab-02
astrona destroy ats-019-lab-030-03-02
```

Authors can run an uncommitted copy and prove the reference solution:

```sh
astrona run -c sections/section-030/module-03/labs/lab-02
astrona test -c sections/section-030/module-03/labs/lab-02
```
