# Question

Solve this question on: `terminal`

## Scenario

The `outpost` team already has the `outpost-scout` composite resource (XR),
a request that Crossplane turns into other objects. Its existing
CompositeResourceDefinition (XRD) defines the namespaced `TeamEnvironment`
application programming interface (API). A Composition tells Crossplane which
resources to create for a request. Composition `scout-stateful` creates a
native StatefulSet and a headless
Service for each request. A StatefulSet manages Pods with stable names; a
headless Service gives those Pods network names without a virtual IP address.
The team now needs a separate ClusterIP Service, which gives clients a stable
address inside the cluster.

## Tasks

1. **Consume the existing API.** Create `TeamEnvironment` `outpost-probe` in
   `outpost`, using `platform.starfleet.io/v1alpha1`. Set `spec.team: probe`,
   `spec.crossplane.compositionRef.name: scout-stateful` and
   `spec.crossplane.compositionUpdatePolicy: Automatic`. It must become
   `Synced=True` and `Ready=True` and own native StatefulSet `outpost-probe`.

2. **Extend the partial Composition.** Keep Composition `scout-stateful` in
   `Pipeline` mode with `function-patch-and-transform`. Leave the existing
   `governing-service` and `statefulset` resource entries unchanged, in that
   order. Append a third entry named `service` whose base is a native `v1`
   `Service` with `spec.type: ClusterIP`, port `9898` and target port `9898`.
   Leave `spec.clusterIP` unset so Kubernetes allocates it. Add exactly three
   `FromCompositeFieldPath` patches, without transforms, in this order:

   | From the XR | To the Service |
   | --- | --- |
   | `metadata.name` | `metadata.name` |
   | `metadata.namespace` | `metadata.namespace` |
   | `metadata.name` | `spec.selector.app` |

   Add a single `readinessChecks` entry with `type: NonEmpty` and
   `fieldPath: spec.clusterIP`, following the existing per-resource pattern.
   Do not create Service objects by hand or wrap them in provider `Object`
   resources.

3. **Upgrade the existing request in place.** Keep the unique identifiers (UIDs) of
   `outpost-scout`, its StatefulSet `outpost-scout` and its headless Service
   `outpost-scout-pods`. Keep its Composition reference `scout-stateful` and
   update policy `Automatic`. It must adopt a newer Composition revision,
   own the new Service `outpost-scout`, and report `Synced=True` and
   `Ready=True`. Do not alter the baseline ConfigMap `lab-state` in `starfleet`.

4. **Prove both Services reach their Pods.** Services `outpost-scout` and
   `outpost-probe` must have allocated cluster IP addresses, select
   `app: outpost-scout` and `app: outpost-probe` respectively, and have ready
   EndpointSlice targets for Pods `outpost-scout-0` and `outpost-probe-0`.
   An EndpointSlice records the Pod addresses behind a Service. Both Pods
   must belong to their matching StatefulSets. From `outpost-scout-0`, an
   Hypertext Transfer Protocol (HTTP) request to each Service on port `9898` must return status `200`.
