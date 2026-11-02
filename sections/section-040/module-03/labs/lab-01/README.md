---
estimated_duration: 15m
---

# Scope A Tenant To One Platform API With RBAC

A graded lab. The cluster has the `TeamEnvironment` API, the namespaces
`outpost` and `starfleet`, and no RBAC for the tenant group `outpost-team`. The
learner writes a Role and RoleBinding and proves the limits. The grader asks the
API server what the identity may do; it does not read the learner's YAML.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-03/labs/lab-01
astrona submit -c sections/section-040/module-03/labs/lab-01
astrona destroy ats-019-lab-040-03
```

Authors: `astrona run -c sections/section-040/module-03/labs/lab-01` runs the
local copy, and `astrona test -c sections/section-040/module-03/labs/lab-01`
proves the grading passes with `solution/solution.yaml`.
