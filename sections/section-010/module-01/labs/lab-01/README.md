---
estimated_duration: 20m
---

# Make A CRD Schema Reject Bad Input

Graded build lab for the CRD module. The `TeamEnvironment` CRD starts with a weak schema: `spec` keeps any field and checks nothing, so a misspelled field, 50 replicas and the contact `nobody` are all stored. The learner replaces the schema with a structural schema that types every field, requires `team`, `size` and `contact`, limits the values, sets defaults and prunes unknown fields. The grader sends objects to the API server with server-side dry runs and checks the answers. It rejects the shortcut `x-kubernetes-preserve-unknown-fields`. No add-ons are needed.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-019-lab-010-01
```

Authors can run the reference solution with `astrona test -c sections/section-010/module-01/labs/lab-01`.
