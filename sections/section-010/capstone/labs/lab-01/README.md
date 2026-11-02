---
estimated_duration: 40m
---

# Publish A Validated And Versioned Platform API

Graded capstone for section 010. The learner replaces a weak, single-version `Database` CustomResourceDefinition (CRD) with a validated API: a structural schema, defaults, CEL rules, two served versions with `v1` as the storage version, `status` and `scale` subresources, printer columns and a short name. Two existing objects must survive the change. The cluster needs only `kind` and no add-ons.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-010/capstone/labs/lab-01
astrona submit -c sections/section-010/capstone/labs/lab-01
astrona destroy ats-019-capstone-010
```

Authors can run the reference solution with `astrona test -c sections/section-010/capstone/labs/lab-01`.
