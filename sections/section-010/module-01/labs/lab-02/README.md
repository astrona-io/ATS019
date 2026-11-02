---
estimated_duration: 25m
---

# Add CEL Rules And Printer Columns To A CRD

Graded build lab for the CRD module. The `TeamEnvironment` CRD starts with a typed schema that already refuses bad values, but it has no rule that compares two fields, no rule that protects `team` from changes, and `kubectl get` shows only a name and an age. The learner adds a CEL rule on `spec` (a small environment runs at most 2 replicas), a transition rule on `team` (`self == oldSelf`), the printer columns Team, Size, Replicas and Age, the short name `teamenv` and the category `platform`. The grader uses server-side dry runs for the rules and reads the output of `kubectl get` for the columns. No add-ons are needed.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-010/module-01/labs/lab-02
astrona submit -c sections/section-010/module-01/labs/lab-02
astrona destroy ats-019-lab-010-01-02
```

Authors can run the reference solution with `astrona test -c sections/section-010/module-01/labs/lab-02`.
