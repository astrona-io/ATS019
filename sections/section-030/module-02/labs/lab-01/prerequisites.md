# Prerequisites

You need to know what a Kubernetes namespace and a custom resource are, and how
to use `kubectl apply` and `kubectl get`. You should know how an OpenAPI v3
schema describes a field: its `type`, `enum`, `minimum`, `maximum`, `default`
and `required`.

The lab environment starts with Crossplane 2.4.2, the `provider-kubernetes`
provider and the `function-patch-and-transform` function already installed.
You do not install anything. The cluster needs outbound internet during the
start, because Crossplane pulls the packages from `xpkg.crossplane.io`. The
start can take several minutes.

Work in a new, empty folder on your machine and run every command from there.
