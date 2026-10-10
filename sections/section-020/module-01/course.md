# Read An Operator's Reconcile Loop

A CustomResourceDefinition only teaches the API server a new kind. The API server stores the objects, checks their schema and serves them, but nothing else happens. Something must read a `Prometheus` object and start a real Prometheus server. That something is a controller, and a controller packaged with its CRDs is an operator.

A controller is a program that watches objects and changes the cluster until it matches what the objects ask for. It repeats one cycle, the reconcile loop: read the desired state, read the actual state, act on the difference, and write status. An operator is a controller plus its CRDs that runs one application on behalf of the user. This module uses the Prometheus Operator, an operator from the Certified Cloud Native Platform Engineer (CNPE) tool list, and reads its work from the cluster.

Keep one sentence in mind: **the custom resource says what you want, the owned objects show what the controller did, and the status says how far it got.** You do not write an operator in this module. You learn to read one, which is what a platform engineer does when a platform API does not work.

The module has four parts. **What An Operator Installs** finds the CRDs, the controller Deployment, its ServiceAccount and its RBAC rules in the cluster. **Follow A Custom Resource To Its Objects** traces a `Prometheus` resource to the StatefulSet, Service and Secrets the controller created, and shows the controller putting back what you change by hand. **Read Conditions And observedGeneration** reads the status the controller writes and proves when that status is old. **Find Why A Reconcile Failed** works through a broken `Prometheus` resource with conditions, events and the controller's logs.

## Learning objectives

After this module you can:

- Name the controller, CRDs and RBAC objects an operator installs, from the cluster.
- Trace a custom resource to the objects its controller created through `ownerReferences`.
- Read `status.conditions` and compare `observedGeneration` with `metadata.generation` to judge whether the controller has acted.
- Find why a reconcile failed from conditions, events and the controller's logs.
- Show that the controller restores an owned object that was changed or deleted by hand.

## Before you start

You need Kubernetes basics: namespaces, Deployments, StatefulSets, Services, Secrets, ServiceAccounts, and the commands `kubectl get`, `kubectl apply`, `kubectl patch` and `kubectl logs`. You also need to know what a CustomResourceDefinition (CRD) is: a Kubernetes object that adds a new resource type to the API server.

You write every file on your own machine, in a new, empty folder. Run every command from that folder.

Your playground is a single-node `kind` cluster running Kubernetes 1.35, with the Prometheus Operator 0.94.1 installed from its release bundle. It holds these objects:

| Namespace | What is in it |
| --- | --- |
| `default` | The `prometheus-operator` Deployment, its ServiceAccount, Service and RBAC |
| `starfleet` | The `scout` web API (podinfo) and its Service, the `shuttle` client pod, a ServiceMonitor for `scout`, the ServiceAccount `prometheus` with read access to Services, Endpoints and Pods |
| `starfleet` | The `Prometheus` resource `starfleet`, which runs, and the `Prometheus` resource `broken`, which names a ServiceAccount that does not exist |

The operator, Prometheus and config reloader images are already on the node, so pods start without a download. Every command in the parts runs against the playground cluster, and `kubectl` already points at it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
