# Summary

A tenant asks for a platform service by applying one small composite resource in its own namespace. Crossplane selects a Composition, runs its function pipeline and applies the result as composed resources. The provider turns each composed `Object` into a real Kubernetes object. Each component has its own job, and each leaves its own record.

## What you learned

The `Synced` condition says that Crossplane ran the Composition and applied the result. The `Ready` condition says that every composed resource is ready. Neither one proves that the application works. The proof is a request to the workload that returns `200`.

Crossplane lists the composed resources in `spec.crossplane.resourceRefs`. The command `crossplane resource trace` reads those references and prints the tree from the composite resource down to the `Object` resources. The tree shows the `Synced` and `Ready` state of each row, so the row that is not ready marks the place to look.

CLI 2.4.1 uses `crossplane resource trace <kind> <name> -n <namespace> -o wide` to show full condition messages and Composition resource names. The CLI reads the same references and conditions available through `kubectl`. Record the failing child's kind, name, reason and message before repair, because reconciliation replaces the error condition.

A failing request leaves its reason in the conditions and the events. A Composition that names a function that is not installed stops the pipeline, and the composite resource reports `Synced` as `False` with a reconcile error. A patch that names a field that does not exist is found by comparing the Composition with the fields of the XRD. You fix both faults in the Composition, not in the request.

Deleting a composite resource removes the composed resources through owner references, and the provider removes the real objects. Orphan deletion keeps them and leaves them without an owner. Use delete for normal removal and orphan only for a planned handover.

Key facts:

- A namespaced composite resource creates its composed resources in its own namespace.
- Crossplane writes `spec.crossplane.compositionRef` and `spec.crossplane.resourceRefs`.
- `crossplane resource trace <kind> <name> -n <namespace>` prints the tree.
- The condition message is more durable than an event.

<!-- astrona:playground:destroy -->
