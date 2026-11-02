---
estimated_duration: 20m
---

# Enable The Status And Scale Subresources

Graded lab for the CRD subresources module. The learner enables the `status` and `scale` subresources on the `v1` version of the `TeamEnvironment` CRD, writes status the way a controller would, and scales an object with `kubectl scale`. The grader checks the paths in the CRD, the `Scale` object the API server returns, and that a normal write cannot change status.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-010/module-02/labs/lab-02
astrona submit -c sections/section-010/module-02/labs/lab-02
astrona destroy ats-019-lab-010-02-02
```

Authors can run the reference solution with `astrona test -c sections/section-010/module-02/labs/lab-02`.
