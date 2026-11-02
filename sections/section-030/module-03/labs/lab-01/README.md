---
estimated_duration: 20m
---

# Provision A TeamEnvironment And Prove It Answers

- **Slug:** ats-019-lab-030-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona hands-on lab, graded

The learner requests a `TeamEnvironment` in the tenant namespace, waits for
`Ready` and proves that the provisioned `scout` workload answers `200`. The
starting cluster has Crossplane, the provider, the function, the XRD and a
working Composition. The graders check the request values, the conditions, the
composed `Object` resources, the Deployment and a real request from `shuttle`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-03/labs/lab-01
astrona submit -c sections/section-030/module-03/labs/lab-01
astrona destroy ats-019-lab-030-03
```

Authors can run an uncommitted copy and prove the reference solution:

```sh
astrona run -c sections/section-030/module-03/labs/lab-01
astrona test -c sections/section-030/module-03/labs/lab-01
```
