# Question

Solve this question on: `terminal`

The platform added the namespaced `TeamEnvironment` API. In `outpost`, existing RoleBindings give `platform-editor` the built-in `edit` role and `platform-reader` the built-in `view` role. Neither role includes the new API yet. This lab needs no Crossplane controller.

## Tasks

1. Add a labelled ClusterRole that aggregates create, get, list, watch, update, patch and delete permissions for `teamenvironments.platform.starfleet.io` into `edit`.
2. Add a separate labelled ClusterRole that aggregates only get, list and watch permissions for the same resource into `view`.
3. Use impersonation to verify both identities in `outpost`. Prove that the reader cannot write TeamEnvironments or read Secrets, and that neither identity can access TeamEnvironments in `starfleet` or create RoleBindings.

## Constraints

- Preserve the existing RoleBindings and the built-in roles' aggregation rules.
- Grant the new permissions through aggregation labels. Do not add bindings or edit the built-in roles directly.
- Add no wildcard, subresource or unrelated API permissions.

Allow a few seconds for the aggregation controller after applying the roles. Learner work: about 15 minutes; cluster startup is separate.
