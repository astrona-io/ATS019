# Summary

Argo Workflows runs a provisioning job as Kubernetes objects. A Workflow lists templates and names an entrypoint. The workflow controller creates one pod for each step and writes the result of every step into the `status` of the Workflow. The phase of the whole run is `Running`, `Succeeded`, `Failed` or `Error`, and each node in `status.nodes` has its own phase and message.

A WorkflowTemplate stores a workflow definition for reuse. Input parameters have default values, and a Workflow that uses `workflowTemplateRef` can override them. The `steps` template runs stages in order, and the `dag` template runs tasks as soon as the tasks they depend on are done. Changing a template affects only Workflows that start afterwards.

Step pods run as a ServiceAccount, and the API server checks its RBAC rules for every call. A dedicated ServiceAccount with a narrow Role in the target namespace is the correct design. A `forbidden` error in the log of a failed step names the identity, the verb, the resource and the namespace, and `kubectl auth can-i --as` proves the fix. Granting `cluster-admin` is never the answer.

A resource template creates or applies one Kubernetes object. With a `successCondition` the step waits until the object reports the wanted status, and a `failureCondition` ends the step as failed. When a workflow stops moving, read the phase, then the failing node, then the pod log or the status of the object the step watches.

Key facts:

- A Workflow is created with `kubectl create` when it uses `generateName`.
- Step pods carry the label `workflows.argoproj.io/workflow`, and the output of a step is in the container `main`.
- `spec.arguments.parameters` holds input values, and a template reads them with `{{workflow.parameters.<name>}}`.
- `spec.serviceAccountName` sets the identity of every step pod.
- A resource step manages one object per template.

<!-- astrona:playground:destroy -->
