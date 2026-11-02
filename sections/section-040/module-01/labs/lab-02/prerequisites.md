# Prerequisites

- Use `kubectl` against the lab cluster. Astrona sets `KUBECONFIG` for you.
- Know that a step pod runs as the ServiceAccount named in `serviceAccountName`, and that the API server checks its Role-based access control (RBAC) rules.
- Know that a Role and a RoleBinding grant permissions in one namespace, and that a ServiceAccount subject needs its own namespace.
- Know that `kubectl auth can-i --as=system:serviceaccount:<namespace>:<name>` tests the permissions of a ServiceAccount.
- Know how to read a Workflow: `status.phase`, the nodes in `status.nodes` and the `main` container log of a step pod.

The cluster is a single-node `kind` cluster running Kubernetes 1.35 and Argo Workflows 4.1.5. The pod images are `ghcr.io/stefanprodan/podinfo:6.15.0` for `scout`.
