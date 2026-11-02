# Prerequisites

You need to know how to install a Crossplane provider with a fixed ServiceAccount name,
how to give that ServiceAccount the least RBAC access it needs, how to write a
CompositeResourceDefinition (XRD) with a validated schema, how to write a Composition in
`mode: Pipeline` with `function-patch-and-transform`, and how to read the `Synced` and
`Ready` conditions of a composite resource with `kubectl` and `crossplane resource trace`.

The lab starts a single-node `kind` cluster with Kubernetes 1.35.8, Crossplane 2.4.2 and
`function-patch-and-transform` 0.11.0. It needs outbound internet access, because you
install `provider-kubernetes` 1.4.1 from `xpkg.crossplane.io`. The start takes a few
minutes. The `crossplane` CLI 2.4.1 is in the `bin` folder of the lab work folder, which
`astrona shell` shows as `/workspace/bin`.
