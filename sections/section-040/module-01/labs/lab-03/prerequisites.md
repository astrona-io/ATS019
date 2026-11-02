# Prerequisites

- Use `kubectl` against the lab cluster. Astrona sets `KUBECONFIG` for you.
- Know that a resource template in a WorkflowTemplate applies a manifest with an `action`, and that `successCondition` and `failureCondition` tell the step when to stop waiting.
- Know that a step pod runs as the ServiceAccount named in `serviceAccountName`, and that a Role and a RoleBinding grant permissions in one namespace.
- Know that a workflow parameter is read with `{{workflow.parameters.<name>}}`.
- Know that `kubectl patch --subresource=status` writes the status of an object.

The cluster is a single-node `kind` cluster running Kubernetes 1.35 and Argo Workflows 4.1.5. The CustomResourceDefinition `TeamEnvironment` (group `platform.starfleet.io`, version `v1alpha1`) is installed. No controller acts on it, so nothing sets its `status.phase` unless you do.
