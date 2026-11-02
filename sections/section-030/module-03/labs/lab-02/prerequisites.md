# Prerequisites

You need to know how to read the conditions of a composite resource with
`kubectl describe`, and what `spec.crossplane.resourceRefs` lists. You also
need to know that a Composition in `mode: Pipeline` runs functions, and that
`function-patch-and-transform` copies values from the request to the composed
resources with patches.

The lab starts a single-node `kind` cluster with Kubernetes 1.35.8, Crossplane
2.4.2, `provider-kubernetes` 1.4.1 and `function-patch-and-transform` 0.11.0.
It needs outbound internet access and takes a few minutes to start. The
`TeamEnvironment` `scout-env` already exists and is broken when the lab opens.
