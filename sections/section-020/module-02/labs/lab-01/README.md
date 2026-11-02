---
estimated_duration: 20m
---

# Hand Over A Dependent Before Deleting Its Owner

Graded build lab for the deletion module. The `TeamEnvironment` CRD has no controller. In `outpost`, the ConfigMap `probe-data` is owned by `probe-env`, and `scout-config` is owned by `scout-env`. The ConfigMap `scout-unowned` only shares the label `team: outpost`. The learner moves `probe-data` to a new owner `probe-env-v2` without recreating it, then deletes both old owners so that only the garbage collector removes `scout-config`. A plain `kubectl delete` of `probe-env`, or a delete by label, destroys `probe-data` and fails the grader.

The cluster needs no add-ons and no internet access.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-020/module-02/labs/lab-01
astrona submit -c sections/section-020/module-02/labs/lab-01
astrona destroy ats-019-lab-020-02
```

Authors can run the reference solution with `astrona test -c sections/section-020/module-02/labs/lab-01`.
