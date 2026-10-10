# Overview: Version A CRD And Enable Subresources (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a
`TeamEnvironment` CustomResourceDefinition in one version and two custom
resources that use it. There is no task, no `astrona submit` and no pass or
fail. Change the CRD, test versions and subresources, `astrona destroy`, start
over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35, with no add-ons.
  `kubectl` is already pointed at it.
- The CustomResourceDefinition `teamenvironments.platform.starfleet.io`. It
  adds the kind `TeamEnvironment` in version `v1alpha1`. This version is both
  served and stored.
- Two `TeamEnvironment` objects in the namespace `outpost`:

  | Object | What is in its `spec` |
  | --- | --- |
  | `alpha` | team `outpost`, size `small`, 2 replicas |
  | `beta` | team `outpost`, size `medium`, 3 replicas |

- The namespaces `starfleet` and `outpost`. No controller acts on the CRD, so
  the learner writes `status` by hand after enabling the status subresource.

## Helpers

Paste these once in each new terminal. `show_versions` prints the served and
storage flags from the CRD. `show_environment` prints the important fields of
one `TeamEnvironment`. `show_scale` asks the Kubernetes scale endpoint for the
same object.

```sh
show_versions() {
  kubectl get crd teamenvironments.platform.starfleet.io \
    -o jsonpath='{range .spec.versions[*]}{.name}{" served="}{.served}{" storage="}{.storage}{"\n"}{end}'
}
show_environment() {
  kubectl -n outpost get teamenvironment "$1" \
    -o jsonpath='apiVersion={.apiVersion} replicas={.spec.replicas} ready={.status.readyReplicas} phase={.status.phase}{"\n"}'
}
show_scale() {
  kubectl -n outpost get --raw "/apis/platform.starfleet.io/v1/namespaces/outpost/teamenvironments/$1/scale"
}
```

Use them like this: `show_versions`, `show_environment alpha`,
`show_scale alpha`.

## Practice tasks

- Add version `v1` with the same schema as `v1alpha1`, mark `v1` as storage,
  and confirm that old objects are still readable through both versions.
- Mark `v1alpha1` as deprecated and read the warning from a request that uses
  that version directly.
- Enable the `status` subresource, then prove that a normal apply cannot write
  `status`.
- Act like a controller by writing `status` with
  `kubectl patch --subresource=status`.
- Enable the `scale` subresource and use `kubectl scale` to change
  `spec.replicas`.
