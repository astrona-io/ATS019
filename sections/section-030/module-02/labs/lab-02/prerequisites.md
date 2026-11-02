# Prerequisites

You need to know what a Crossplane Composition is and how a pipeline step calls
`function-patch-and-transform`. You should know the two patch types
`FromCompositeFieldPath` and `ToCompositeFieldPath`, and what a `provider-kubernetes`
`Object` is: a managed resource that wraps a Kubernetes manifest in
`spec.forProvider.manifest`.

The lab environment starts with Crossplane 2.4.2, the provider and the
function installed. The XRD, a Composition and a request are already applied.
The cluster needs outbound internet during the start, and the start can take
several minutes.

Work in a new, empty folder on your machine and run every command from there.
