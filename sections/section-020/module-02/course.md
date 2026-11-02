# Manage Deletion With Finalizers And Owner References

Deleting a platform request must also remove the objects it created. Some objects can go at once. Others must stay until a controller finishes cleanup. Kubernetes records both decisions in the object's metadata, so you can predict what deletion will do before you run it.

An `ownerReference` is a link from a dependent object to its owner. The garbage collector is a Kubernetes controller that deletes dependents whose owners are gone. A finalizer is a name in `metadata.finalizers` that keeps an object in the API until the component responsible for that name finishes its work and removes it.

The module has four parts. **Owner References And The Garbage Collector** reads the objects owned by Prometheus and gives a custom resource its own dependent ConfigMap. **Choose A Cascading Deletion Mode** compares background, foreground and orphan deletion. **Finalizers And deletionTimestamp** requests deletion of an object that cannot finish cleanup. **Restore A Cleanup Worker** finds why cleanup stopped, starts the worker and proves that both cleanup and deletion finish.

## Learning objectives

After this module you can:

- Predict which dependent objects the garbage collector deletes when an owner is deleted.
- Choose foreground, background or orphan cascading deletion with `kubectl delete --cascade`.
- Explain why a finalizer keeps an object in a terminating state and which component must remove it.
- Diagnose a stuck deletion and restore cleanup instead of removing the finalizer by hand.

## Before you start

You need Kubernetes basics: namespaces, ConfigMaps, StatefulSets, Jobs, ServiceAccounts and the commands `kubectl get`, `kubectl apply`, `kubectl delete` and `kubectl logs`. A CustomResourceDefinition (CRD) adds a resource type to the Kubernetes application programming interface (API). A custom resource is one object of that type. An operator is a controller packaged with CRDs that manages an application for you.

Write each example file in a new, empty folder on your machine. Run every command from that folder. Your playground runs Kubernetes 1.35.8 and Prometheus Operator 0.94.1 in a single-node `kind` cluster.

| Namespace | What is in it |
| --- | --- |
| `default` | The `prometheus-operator` controller Deployment |
| `starfleet` | An available `Prometheus` resource `starfleet`, its StatefulSet, Service and Secrets, and the ServiceAccount `prometheus` |
| `starfleet` | `scout-settings`, a ConfigMap with the finalizer `platform.starfleet.io/cleanup`, and `scout-cache`, which the cleanup worker must delete first |
| `starfleet` | The suspended Job `scout-cleanup`, with a ServiceAccount and permissions limited to those two ConfigMaps |
| `outpost` | An empty namespace for ownership examples |

The `TeamEnvironment` CRD is installed, but no controller acts on its objects. You add their owner references by hand to see what Kubernetes itself does. The cleanup Job is a small, one-time recovery example, not a full operator. It starts suspended, so no worker removes the custom finalizer until you restore it. All required container images are preloaded, and `kubectl` points at this playground.

Launch your playground now, and keep it running while you read:

<!-- astrona:playground -->
