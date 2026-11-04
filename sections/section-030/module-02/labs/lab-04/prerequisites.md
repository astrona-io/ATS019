# Prerequisites

You need to read a CompositeResourceDefinition (XRD), the Crossplane object
that defines a platform API, and create a composite resource (XR) of that
type. You should understand a Composition pipeline, a patch that copies a
field, and the labels that a Kubernetes Service uses to select Pods.

The lab installs Crossplane 2.4.2 and `function-patch-and-transform` 0.11.0 on
Kubernetes 1.35.8. It supplies the namespaced `TeamEnvironment` API, a partial
Composition and the working `outpost-scout` request. Crossplane creates native
Kubernetes objects directly here; no provider is needed. Bootstrap grants
Crossplane the StatefulSet permissions it needs. The terminal has `kubectl`.
Outbound internet is needed during setup to fetch the function package.

Work in a new, empty folder on your machine and run every command from there.
