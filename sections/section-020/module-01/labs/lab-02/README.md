---
estimated_duration: 25m
---

# Repair A Prometheus Resource That Cannot Reconcile

Graded troubleshooting lab for the operators module. The Prometheus Operator 0.94.1 is installed. The `Prometheus` resource `tenant` in `outpost` has two faults: it reads extra scrape jobs from a Secret that does not exist, so `Reconciled` is `False`, and it names a ServiceAccount that does not exist, so the StatefulSet cannot create its pod. The learner reads the conditions, the events and the operator log, and fixes both causes without removing the scrape configuration and without giving Prometheus more than read access. The start takes a few minutes because the Prometheus Operator bundle is downloaded from GitHub.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-020/module-01/labs/lab-02
astrona submit -c sections/section-020/module-01/labs/lab-02
astrona destroy ats-019-lab-020-01-02
```

Authors can run the reference solution with `astrona test -c sections/section-020/module-01/labs/lab-02`.
