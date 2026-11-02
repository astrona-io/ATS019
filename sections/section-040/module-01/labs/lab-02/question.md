---
estimated_duration: 25m
---

# Question

Solve this question on: `terminal`

The WorkflowTemplate `deploy-scout` in the namespace `starfleet` applies a Deployment named `scout` and a Service named `scout` in the namespace `outpost`. The step pods run as the ServiceAccount `provisioner` in `starfleet`. Every Workflow that you submit from the template ends as `Failed`. Argo Workflows already lets the step pods report their results, so that part is correct.

Find out why the Workflow fails, and fix it so that:

1.  A new Workflow from `deploy-scout` ends as `Succeeded`.
2.  The Deployment `scout` (image `ghcr.io/stefanprodan/podinfo:6.15.0`) and the Service `scout` (port `9898`) exist in `outpost`, and the Deployment is `Available`.
3.  The ServiceAccount `provisioner` is allowed to `get`, `create` and `patch` Deployments and Services in `outpost`.

Constraints:

* Fix the permissions only. Do not change the WorkflowTemplate and do not use another ServiceAccount.
* Grant nothing wider than the steps need. `provisioner` must not be able to `delete` Deployments, Services or Secrets in `outpost`, must not read Secrets there, and must not create Deployments in `default` or `starfleet`.
* Do not use `cluster-admin`, a ClusterRoleBinding or the wildcard `*` for verbs or resources.

The grader removes the `scout` objects, submits a new Workflow from `deploy-scout`, waits for it to end, and then asks the API server what `provisioner` may and may not do.
