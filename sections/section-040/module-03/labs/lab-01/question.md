# Question

Solve this question on: `terminal`

## Scenario

The `outpost` team files its environment requests as `TeamEnvironment`
objects (API group `platform.starfleet.io`) in the namespace `outpost`. The
platform team must give the group `outpost-team` exactly the rights it needs
to file and follow those requests. A Crossplane controller builds the
workloads, so the tenant never needs to touch Deployments or Secrets. The
user `outpost-dev` is a member of the group. Right now the group has no
rights at all.

## Tasks

1. **Create a Role.** In the namespace `outpost`, create a Role that allows
   exactly the verbs `create`, `get`, `list` and `watch` on the resource
   `teamenvironments` in the API group `platform.starfleet.io`. The Role must
   grant nothing else. The name is your choice.

2. **Bind the group.** In the namespace `outpost`, create a RoleBinding that
   gives the Role to the group `outpost-team`. The subject must be the group,
   not the user `outpost-dev`.

3. **Stay inside the limits.** After your change, members of `outpost-team`
   must not be able to update, patch or delete a `TeamEnvironment`. They must
   not be able to create Deployments, Pods or Services, read Secrets, list
   ConfigMaps or create RoleBindings in `outpost`. They must not be able to
   create a `TeamEnvironment` in `starfleet`, `default` or `kube-system`, or
   list `TeamEnvironment` objects in all namespaces. Do not bind
   `cluster-admin`, `edit` or `view`, and do not use a ClusterRoleBinding.

4. **Prove it.** With `kubectl auth can-i`, `--as outpost-dev` and
   `--as-group outpost-team`, check one allowed action and the denied actions
   above.
