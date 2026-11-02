---
estimated_duration: 15m
---

# Make A Stale Operator Status Current

Graded troubleshooting lab for the operators module. The Prometheus Operator 0.94.1 is installed, and the `Prometheus` resource `starfleet` has `spec.logLevel: debug`, but its status is older than its spec because the controller is not running. The learner compares `observedGeneration` with `metadata.generation`, finds the stopped controller and starts it, and proves the controller acted. The start takes a few minutes because the Prometheus Operator bundle is downloaded from GitHub.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-020/module-01/labs/lab-01
astrona submit -c sections/section-020/module-01/labs/lab-01
astrona destroy ats-019-lab-020-01
```

Authors can run the reference solution with `astrona test -c sections/section-020/module-01/labs/lab-01`.
