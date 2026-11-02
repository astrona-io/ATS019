# Prerequisites

You need to know what an owner reference is, how the Kubernetes garbage
collector deletes dependents, and that `kubectl delete` accepts the option
`--cascade` with the values `background`, `foreground` and `orphan`.

The lab starts a single-node `kind` cluster with Kubernetes 1.35.8, Crossplane
2.4.2, `provider-kubernetes` 1.4.1 and `function-patch-and-transform` 0.11.0.
It needs outbound internet access and takes several minutes to start, because
the setup also creates a ready `TeamEnvironment` and checks that `scout`
answers.
