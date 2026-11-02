---
estimated_duration: 15m
---

# Install provider-kubernetes And Reach Healthy

Graded lab for the Crossplane providers module. The learner installs `provider-kubernetes` 1.4.1 on a fresh Crossplane 2.4.2 cluster, with a fixed ServiceAccount name set through a `DeploymentRuntimeConfig`, and proves that the provider is healthy. The cluster needs outbound internet access to pull the package from `xpkg.crossplane.io`.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-01/labs/lab-01
astrona submit -c sections/section-030/module-01/labs/lab-01
astrona destroy ats-019-lab-030-01
```

Authors can run the reference solution with `astrona test -c sections/section-030/module-01/labs/lab-01`.
