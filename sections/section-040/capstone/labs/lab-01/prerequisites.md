# Prerequisites

You need Kubernetes basics: namespaces, Services, ServiceAccounts, Role-based access control (RBAC), and the commands `kubectl get`, `kubectl apply`, `kubectl logs`, `kubectl exec` and `kubectl auth can-i`.

You also need to know the three parts of the self-service path. Argo Events receives a webhook request and starts a Workflow through an EventSource, an EventBus and a Sensor. Argo Workflows runs the Workflow from a WorkflowTemplate. Crossplane turns a `TeamEnvironment` custom resource into a Deployment and a Service through a Composition.

The lab runs a single-node `kind` cluster with Kubernetes 1.35.8, Crossplane 2.4.2, Argo Workflows 4.1.5 and Argo Events 1.9.11. The cluster needs outbound internet access, and it takes several minutes to start because Crossplane pulls its packages.
