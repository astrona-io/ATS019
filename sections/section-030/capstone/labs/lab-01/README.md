---
estimated_duration: 40m
---

# Build A Self-Service Team Environment API

- **Slug:** ats-019-capstone-030
- **Author:** Paris Nakita Kejser
- **Type:** Astrona hands-on capstone, graded

Capstone for the section on platform APIs with Crossplane. The cluster starts with
Crossplane 2.4.2, `function-patch-and-transform` 0.11.0 and a `shuttle` client pod in
`outpost`. The learner installs `provider-kubernetes` 1.4.1 and its ProviderConfig,
completes the RBAC (the starting Role covers Deployments only), defines the
`TeamEnvironment` XRD, writes the Composition, requests an environment from `outpost`
and proves that `scout` answers with `200`.

The graders check behaviour: the provider permissions with `kubectl auth can-i`, the
schema with server-side dry runs, the workload with a request from `shuttle`, and the
Composition by changing `spec.replicas` of the request and watching the Deployment
follow. They reject `cluster-admin`, `x-kubernetes-preserve-unknown-fields`, a second
ProviderConfig and objects created by hand.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/capstone/labs/lab-01
astrona submit -c sections/section-030/capstone/labs/lab-01
astrona destroy ats-019-capstone-030
```

Authors can run an uncommitted copy and prove the reference solution:

```sh
astrona run -c sections/section-030/capstone/labs/lab-01
astrona test -c sections/section-030/capstone/labs/lab-01
```
