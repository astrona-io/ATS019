---
estimated_duration: 20m
---

# Add A v1 Version And Deprecate v1alpha1

Graded lab for the CRD versions module. The learner adds a `v1` version to the `TeamEnvironment` CRD, makes it the storage version, keeps `v1alpha1` served but deprecated, keeps the two existing objects, and creates a third object through `v1`. The grader checks the CRD fields, the real deprecation warning from `kubectl`, and that both versions still reject bad input.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-010/module-02/labs/lab-01
astrona submit -c sections/section-010/module-02/labs/lab-01
astrona destroy ats-019-lab-010-02
```

Authors can run the reference solution with `astrona test -c sections/section-010/module-02/labs/lab-01`.
