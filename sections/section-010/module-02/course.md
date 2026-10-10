# Version A CRD And Enable Subresources

A platform API changes after teams start using it. A field gets a clearer name, a stable version replaces an alpha version, and a controller needs a safe place to write status. If the CustomResourceDefinition does not plan for those changes, every user and every controller must change at the same time.

A CustomResourceDefinition (CRD) is a Kubernetes object that adds a new resource type to the API server. This module keeps the same `TeamEnvironment` kind and changes how the API server serves it. You add a second version, choose the storage version, deprecate the old version, then enable the `status` and `scale` subresources.

Keep one sentence in mind: **versions decide how clients see a custom resource, and subresources decide which actor may write which part of it.** No controller runs in this module. You act like the controller when you write status, so the API server behaviour is visible.

The module has four parts. **Served Versions And Storage Versions** adds `v1` beside `v1alpha1`, moves storage to `v1`, and reads `status.storedVersions`. **Deprecate A Served Version** marks `v1alpha1` as deprecated and reads the warning from the API server. **Write Status Through The Status Subresource** enables `/status` and proves that a normal spec write cannot change status. **Scale A Custom Resource** enables `/scale` and uses `kubectl scale` to change `spec.replicas`.

## Learning objectives

After this module you can:

- Add a second version to a CRD and choose which version is served and which is the storage version.
- Read which versions may still be in etcd from `status.storedVersions`, and why the API server never cleans that list by itself.
- Mark a version deprecated and read the warning `kubectl` prints.
- Enable the `status` subresource and show that a spec update cannot change status.
- Enable the `scale` subresource and scale a custom resource with `kubectl scale`.

## Before you start

You need Kubernetes basics: namespaces, YAML manifests, custom resources, and the commands `kubectl get`, `kubectl apply`, `kubectl patch` and `kubectl scale`. You also need to know that `spec` is the desired state a user writes, and `status` is the observed state a controller writes.

You write every file on your own machine, in a new, empty folder. Run every command from that folder.

Your playground is a single-node `kind` cluster running Kubernetes 1.35, with no add-ons. It holds these objects:

| Object | What it is |
| --- | --- |
| CRD `teamenvironments.platform.starfleet.io` | Adds the kind `TeamEnvironment` in version `v1alpha1`; the version is served and stored |
| `TeamEnvironment` `alpha` in `outpost` | A small environment with 2 replicas |
| `TeamEnvironment` `beta` in `outpost` | A medium environment with 3 replicas |

The namespaces `starfleet` and `outpost` exist. No controller acts on the CRD, and no subresources are enabled at the start. Every command in the parts runs against the playground cluster, and `kubectl` already points at it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
