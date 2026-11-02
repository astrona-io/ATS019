# Prerequisites

You need to know namespaces, Roles, RoleBindings and `kubectl auth can-i`. The
cluster is a single-node `kind` cluster on Kubernetes 1.35.8. It needs no
outbound internet access.

At the start, the namespaces `outpost` and `starfleet` exist, and the
`TeamEnvironment` API (`platform.starfleet.io/v1alpha1`) is installed as a
CustomResourceDefinition. No Role or RoleBinding exists for the group
`outpost-team`. Your own administrator account may impersonate other
identities with `kubectl --as` and `--as-group`.
