# Prerequisites

- Use `kubectl` against the lab cluster. Astrona sets `KUBECONFIG` for you.
- Know that a Workflow is a Kubernetes object and that the workflow controller creates one pod for each step.
- Know that a WorkflowTemplate stores a workflow definition with `spec.arguments.parameters`, and that a Workflow starts it with `workflowTemplateRef`.
- Know that a `dag` template runs a task when all tasks it depends on are done.

The cluster is a single-node `kind` cluster running Kubernetes 1.35 and Argo Workflows 4.1.5. The namespace `starfleet` exists, and its `default` ServiceAccount may report step results. Step pods use the image `curlimages/curl`.
