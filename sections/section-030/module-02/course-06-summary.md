# Summary

A platform API starts with a schema. A CompositeResourceDefinition (XRD) in `apiextensions.crossplane.io/v2` defines a new resource type, and Crossplane turns it into a CustomResourceDefinition. A namespaced scope puts each request in the tenant's namespace. The API server validates every request against the schema before Crossplane acts on it, so defaults and limits protect the platform.

A Composition decides what each request creates. In Crossplane 2.x it always runs as a pipeline of composition functions. Crossplane sends the composite resource to the function, and the function returns the desired resources. Here the function was `function-patch-and-transform`, and the resources were `provider-kubernetes` `Object` wrappers, so the cluster created the Deployment and Service without any cloud account.

Patches connect the request to the result. `FromCompositeFieldPath` copies a request value into a composed resource. `ToCompositeFieldPath` copies an observed value back into the status, but only when the XRD schema declares that field. The proof of a working API is the status of the composite resource, the objects it owns, and a request that returns `200`.

Debugging follows the same chain. `crossplane composition render` previews the pipeline locally. On a live cluster, the conditions and events of the composite resource show a bad function reference first. The Composition is the place to repair it.

Crossplane 2.x can also compose native Kubernetes resources directly. Their patches use native field paths, and explicit readiness checks read fields such as a StatefulSet's `status.readyReplicas` and a Service's `spec.clusterIP`. A client Service selects the labels on the StatefulSet's Pods; an allocated address alone does not prove that traffic reaches them.

With the `Automatic` Composition update policy, an existing composite resource adopts newer Composition revisions. Adding a resource template can add a Service without replacing the request or its workload. Compare UIDs before and after the change, then check ownership, ready EndpointSlice targets and an HTTP request.

Key facts:

- An XRD name is `<plural>.<group>`, and its group and names cannot change later.
- Claims exist only for `scope: LegacyCluster`.
- A Composition in `Pipeline` mode names each function with `functionRef`.
- `crossplane resource trace` follows a composite resource to its composed resources.

<!-- astrona:playground:destroy -->
