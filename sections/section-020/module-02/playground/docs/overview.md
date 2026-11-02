# Overview: Manage Deletion With Finalizers And Owner References (Playground)

This playground gives you real objects to inspect, delete and recreate. An owner reference links a dependent object to its owner. A finalizer keeps an object in the Kubernetes application programming interface (API) until cleanup finishes. There is nothing to submit and no grading.

## What's in the box

The single-node `kind` cluster runs Kubernetes 1.35.8 and Prometheus Operator 0.94.1. An operator is a controller packaged with CustomResourceDefinitions (CRDs), which add resource types to the API. The operator runs in `default` and manages the `Prometheus` resource `starfleet` in the namespace of the same name.

| Namespace | Objects |
| --- | --- |
| `default` | The operator Deployment and its permissions |
| `starfleet` | An available Prometheus server, its owned StatefulSet, Service and Secrets |
| `starfleet` | The ConfigMaps `scout-settings` and `scout-cache` |
| `starfleet` | The suspended Job `scout-cleanup`, its ServiceAccount, Role and RoleBinding |
| `outpost` | An empty namespace for your custom resources and ConfigMaps |

The `TeamEnvironment` CRD is installed without a controller. A custom resource is one object of a type that a CRD adds. Its schema requires `spec.team` and `spec.size`; size accepts `small`, `medium` or `large`.

`scout-settings` has the custom finalizer `platform.starfleet.io/cleanup`. Its cleanup contract is to delete `scout-cache` before releasing `scout-settings`. The Job is a one-time cleanup worker. It starts suspended, so no pod performs cleanup. The Prometheus Operator does not handle this custom finalizer. The worker's images are preloaded, as are the operator and Prometheus images.

## Helpers

Paste these functions into each new terminal. `show_owners` lists owner names on common resource types. `show_deletion` prints the fields that decide whether deletion can finish. A unique identifier (UID) distinguishes one object from a later object with the same name.

```sh
show_owners() {
  kubectl -n "$1" get statefulset,service,secret,configmap \
    -o custom-columns='KIND:.kind,NAME:.metadata.name,OWNER:.metadata.ownerReferences[*].name'
}
show_deletion() {
  kubectl -n "$1" get "$2" "$3" \
    -o jsonpath='uid={.metadata.uid} deletionTimestamp={.metadata.deletionTimestamp} finalizers={.metadata.finalizers}{"\n"}'
}
```

Use `show_owners starfleet` or `show_deletion starfleet configmap scout-settings`. These functions only read objects; they do not change the cluster.

## Practice tasks

- Create a `TeamEnvironment` and two ConfigMaps in `outpost`. Give only one ConfigMap an owner reference with the owner's real UID. Delete the owner and check which ConfigMap remains.
- Repeat with foreground deletion and `blockOwnerDeletion: true`. Check that both the owner and its dependent are gone when deletion completes.
- Repeat with orphan deletion. Read the surviving ConfigMap's owner references, then decide who now owns its cleanup.
- Request deletion of `scout-settings` with `--wait=false`. Compare its deletion timestamp and finalizers before and after the request. Check whether the ordinary ConfigMap table shows the terminating state.
- Inspect the suspended cleanup Job and its permissions. Start it only after requesting deletion of `scout-settings`, then read every container's logs and confirm that both ConfigMaps are gone.
