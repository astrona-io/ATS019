# Define A Platform API With An XRD And Composition

<!-- astrona:playground -->

A platform team wants tenant teams to ask for a workload with one small object, and not with a Deployment, a Service and a pile of settings. Crossplane makes that possible. A CompositeResourceDefinition (XRD) defines a new API type, and a Composition says which objects Crossplane creates for each request of that type.

This module builds that pair from nothing. The example API is `TeamEnvironment`. A tenant in the `outpost` namespace creates one `TeamEnvironment`, and Crossplane creates the `scout` Deployment and Service for it. Everything runs inside the `kind` cluster, so Crossplane never calls a cloud provider.

The module has four parts. **From A CRD To An XRD** writes the API and its schema. **Compose Resources With A Pipeline** adds a Composition that creates the first workload object. **Patch Values In And Out** copies request values into the workload and writes the result back to status. **Render And Debug A Composition** previews a Composition on your machine and reads the status of a Composition that points at a missing function.

## Learning objectives

After this module you can:

- Write an XRD in `apiextensions.crossplane.io/v2` with a namespaced scope and a validated schema.
- Reference `function-patch-and-transform` from a Composition in `Pipeline` mode.
- Compose a Deployment and a Service from one composite resource.
- Patch values from the composite resource into composed resources and write fields back to status.
- Preview a Composition with `crossplane composition render` and read the status of a broken one.

## Before you start

You need Kubernetes basics (namespaces, Deployments, Services, `kubectl apply`) and a CustomResourceDefinition (CRD): an object that adds a new resource type to the Kubernetes API. Write each example file in a new, empty folder and run every command from there.

Your playground runs Kubernetes 1.35.8 with Crossplane 2.4.2. Three Crossplane packages are installed. `provider-kubernetes` 1.4.1 is a provider: it installs the CRDs and the controller that create Kubernetes objects on behalf of Crossplane. It has a working `ProviderConfig` named `in-cluster` and the permissions it needs. `function-patch-and-transform` 0.11.0 is a composition function. The `crossplane` command line tool (CLI) 2.4.1 is on your path.

No XRD or Composition exists yet. The tenant namespace is `outpost`, and the platform team's namespace is `starfleet`.
