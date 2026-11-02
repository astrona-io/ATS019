---
estimated_duration: 30m
---

# Question

Solve this question on: `terminal`

The platform team offers a `TeamEnvironment` API (`platform.starfleet.io/v1alpha1`, resource `teamenvironments`). A request for an environment must not count as done when the object is created. It is done when the object reports `status.phase: Ready`. The `drifter` team in `outpost` wants a workflow that makes this request and waits.

Build it in the namespace `starfleet`:

1.  Create a WorkflowTemplate named `request-environment`. It runs as the ServiceAccount `provisioner` (set `serviceAccountName` in the template).
2.  The template has two parameters: `name` with the default `outpost-env`, and `team` with the default `outpost`.
3.  Its entrypoint is one resource step with `action: create`. The step creates a `TeamEnvironment` in the namespace `outpost`. The object takes its name from the parameter `name`, and `spec.team` from the parameter `team`.
4.  The step succeeds when `status.phase` is `Ready` and fails when `status.phase` is `Failed`.
5.  Give `provisioner` the permissions to do this in `outpost`: `get`, `list`, `watch` and `create` on `teamenvironments`.

Constraints:

* Grant nothing wider. `provisioner` must not `delete` or `update` TeamEnvironments, must not write their status, and must not create Deployments in `outpost`.
* Do not use `cluster-admin`, a ClusterRoleBinding or the wildcard `*`.
* Do not set the status yourself inside the workflow. A controller owns the status.

No controller runs in this cluster. The grader plays the controller: it creates a Workflow from your template, checks that the Workflow keeps running, then writes `status.phase` on the object.
