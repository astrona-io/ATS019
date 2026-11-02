# Prerequisites

You need Kubernetes basics: namespaces, Services, ServiceAccounts, Role-based access control (RBAC), and the commands `kubectl get`, `kubectl apply`, `kubectl logs` and `kubectl exec`.

You also need to know how Argo Events starts a Workflow. An EventSource receives an event, an EventBus carries it, and a Sensor with a filter and a trigger starts a Workflow from a WorkflowTemplate. The lab does not need any file from your machine except the YAML files you write.

The lab runs a single-node `kind` cluster with Kubernetes 1.35.8, Argo Workflows 4.1.5 and Argo Events 1.9.11. The cluster needs outbound internet access. It takes a few minutes to start.
