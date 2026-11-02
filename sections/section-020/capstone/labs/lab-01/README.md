---
estimated_duration: 40m
---

# Diagnose And Repair Operator-Managed Resources

Graded capstone for the operators section. The cluster runs the Prometheus Operator 0.94.1 and three faults in the namespace `outpost`. The `Prometheus` resource `outpost-metrics` does not reconcile, two ConfigMaps lack the owner reference that links them to the `TeamEnvironment` `scout-env`, and the ConfigMap `scout-settings` is stuck in Terminating because its cleanup worker is suspended and cannot delete `scout-cache`. The learner reads conditions, events and permissions, and fixes each cause without removing the finalizer by hand. The cluster needs outbound internet access to download the operator bundle.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-020/capstone/labs/lab-01
astrona submit -c sections/section-020/capstone/labs/lab-01
astrona destroy ats-019-capstone-020
```

Authors can run the reference solution with `astrona test -c sections/section-020/capstone/labs/lab-01`.
