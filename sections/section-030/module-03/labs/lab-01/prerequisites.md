# Prerequisites

You need to know what a namespace, a Deployment and a Service are, and the
commands `kubectl apply`, `kubectl get`, `kubectl wait` and `kubectl exec`.

You also need to know that a composite resource (XR) is one object of the type
that a CompositeResourceDefinition (XRD) defines, and that a Composition says
which objects Crossplane creates for each composite resource.

The lab starts a single-node `kind` cluster with Kubernetes 1.35.8 and
Crossplane 2.4.2. It installs `provider-kubernetes` 1.4.1 and
`function-patch-and-transform` 0.11.0 from `xpkg.crossplane.io`, so it needs
outbound internet access and takes a few minutes to start. The `TeamEnvironment`
XRD, a working Composition and the `shuttle` pod are ready when the lab opens.
No `TeamEnvironment` exists yet.
