# Summary

A CustomResourceDefinition adds a kind to the API server, but only a controller makes an object of that kind do something. An operator is that controller packaged with its CRDs, and a platform engineer must be able to find it, read what it built and read what it reports.

## What you learned

An operator installs CRDs in its own API group, a Deployment that runs the controller, a ServiceAccount the controller runs as, and RBAC rules that give that ServiceAccount its permissions. `kubectl api-resources --api-group` lists the kinds, and `kubectl auth can-i --as=system:serviceaccount:<namespace>:<name>` shows what the controller may change. The Prometheus Operator may only read its custom resources and write their status; it may create StatefulSets, Services and Secrets, but not Deployments.

The controller runs the reconcile loop: an event starts a reconcile, the controller compares the custom resource with the cluster, creates or changes objects until they match, and writes status. Every object it builds carries an `ownerReference` with the owner's kind, name and `uid`, and `controller: true` marks the owner that manages it. Ownership is a chain: the `Prometheus` resource owns the StatefulSet, and the StatefulSet owns the pod. The controller undoes changes made by hand to its objects at the next reconcile, so the fix always goes into the custom resource.

Status comes as conditions with a `type`, a `status`, a `reason` and a `message`. `metadata.generation` counts `spec` changes, and `observedGeneration` says which generation the controller last acted on; when it is lower, the status is old, however healthy it looks. A controller that is down leaves old status behind and catches up when it starts again.

A failed reconcile shows up in one of two ways. `Reconciled False` means the operator itself could not finish, and its message and the controller log say why. `Reconciled True` with `Available False` means the operator built everything but something further down failed, so the events on the owned objects hold the cause. The key facts to remember are these:

- Find the controller, its ServiceAccount and its RBAC before you debug its custom resources.
- Follow `ownerReferences` down to the objects that failed.
- Compare `observedGeneration` with `generation` before you trust a condition.
- Fix the custom resource or what it references, never the owned objects.

<!-- astrona:playground:destroy -->
