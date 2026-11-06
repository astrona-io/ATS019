# Prerequisites

You can read a Crossplane composite resource, an object defined by a
CompositeResourceDefinition, and its `status.conditions`. You can use
`kubectl get`, `kubectl edit` and `kubectl apply` with a namespace.

The environment installs Crossplane 2.4.2, Crossplane command-line interface
(CLI) 2.4.1, provider-kubernetes 1.4.1 and
function-patch-and-transform 0.11.0. The CLI is available on `terminal`
through the work folder's `bin` directory. No cloud account is needed.
The setup needs internet access to download the CLI and Crossplane packages.
