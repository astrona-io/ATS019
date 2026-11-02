---
estimated_duration: 20m
---

# Repair A Provider That Cannot Sync An Object

Graded troubleshooting lab for the Crossplane providers module. `provider-kubernetes` 1.4.1 is healthy, the ProviderConfig `in-cluster` exists in `outpost`, and the `Object` `scout` is stuck with `Synced False`. The Role that should let the provider manage Services only allows reading them. The learner finds the cause in the `Synced` condition and grants the missing verbs, without widening access. The cluster needs outbound internet access, and the start takes a few minutes while Crossplane pulls the provider package.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-01/labs/lab-02
astrona submit -c sections/section-030/module-01/labs/lab-02
astrona destroy ats-019-lab-030-01-02
```

Authors can run the reference solution with `astrona test -c sections/section-030/module-01/labs/lab-02`.
