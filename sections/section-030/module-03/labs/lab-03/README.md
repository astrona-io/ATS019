---
estimated_duration: 15m
---

# Delete A Composite Resource Without Losing Its Workload

- **Slug:** ats-019-lab-030-03-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona hands-on lab, graded

The learner deletes a `Ready` `TeamEnvironment` with `--cascade=orphan`, so the
`scout` workload survives. The setup records the UIDs of the Deployment, the
Service and the `Object` resources in the ConfigMap `lab-baseline`. The graders
compare against those UIDs, so a workload recreated by hand fails.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-03/labs/lab-03
astrona submit -c sections/section-030/module-03/labs/lab-03
astrona destroy ats-019-lab-030-03-03
```

Authors can run an uncommitted copy and prove the reference solution:

```sh
astrona run -c sections/section-030/module-03/labs/lab-03
astrona test -c sections/section-030/module-03/labs/lab-03
```
