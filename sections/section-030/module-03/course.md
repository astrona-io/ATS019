# Provision And Trace A Composite Resource

A platform API is only useful if a tenant can use it and the platform team can see what it did. In Crossplane, a tenant applies one small object, and Crossplane creates many objects from it. When something goes wrong, you need a way to follow that one object to everything it created.

A composite resource (XR) is one object of the type that a CompositeResourceDefinition (XRD) defines. In this module the type is `TeamEnvironment`, and a team in the `outpost` namespace requests one. A Composition is the Crossplane object that says which resources to create for each composite resource. A managed resource is an object that a provider controls. Here the provider is `provider-kubernetes`, and its managed resource is an `Object`, which wraps any Kubernetes manifest and applies it to the cluster.

The module has five parts. **Request A Composite Resource** applies a `TeamEnvironment` from `outpost`, waits for it to be ready and proves that the `scout` workload answers. **Trace A Composite Resource** follows the request to every object it created, with `kubectl` and with `crossplane resource trace`. **Read A Failing Composite Resource** uses conditions and events to find out why a composite resource never becomes ready. **Update And Delete A Composite Resource** changes a request, deletes it, and compares deleting the composed resources with orphaning them. **Trace With The Crossplane CLI** installs the pinned CLI, reads full condition messages and records a failing child before repair.

## Learning objectives

After this module you can:

- Request a composite resource in a tenant namespace and follow it to `Ready`.
- Trace a composite resource to every composed resource and managed resource with `crossplane resource trace`.
- Read the `Synced` and `Ready` conditions on a composite resource and on its composed resources to find the one that fails.
- Diagnose a Composition that references a missing function or patches a field that does not exist.
- Choose between deleting a composite resource and orphaning its composed resources.
- Install CLI 2.4.1, trace a namespaced request with wide output and preserve the failing child's diagnosis before repair.

## Before you start

You need Kubernetes basics: namespaces, Deployments, Services and the commands `kubectl get`, `kubectl apply`, `kubectl describe` and `kubectl delete`. You also need to know what a CustomResourceDefinition is: an object that adds a new resource type to the Kubernetes application programming interface (API). A Crossplane XRD does the same job for a platform API, and Crossplane turns it into a CRD for you.

Write each example file in a new, empty folder on your machine. Run every command from that folder. Your playground runs Kubernetes 1.35 in a single-node `kind` cluster with Crossplane 2.4.2. It needs outbound internet access, because Crossplane pulls its providers and functions from a package registry.

The playground has these parts ready:

| Item | What it is |
| --- | --- |
| `provider-kubernetes` 1.4.1 | The provider, with a working `ProviderConfig` |
| `function-patch-and-transform` 0.11.0 | The composition function that the Compositions call |
| XRD `TeamEnvironment` | The platform API; the composite resource is namespaced |
| A working Composition | Creates the `scout` Deployment and Service for a request |
| Composition `teamenvironment-with-cache` | Broken on purpose; a composite resource that selects it never becomes ready |
| Namespace `outpost` | One ready `TeamEnvironment` and a `shuttle` client pod |

The `crossplane` command-line tool is installed too. It is released separately from Crossplane, and the playground uses version 2.4.1 with Crossplane 2.4.2. Its trace command is still marked `[BETA]` in `--help`.

Launch your playground now, and keep it running while you read:

<!-- astrona:playground -->
