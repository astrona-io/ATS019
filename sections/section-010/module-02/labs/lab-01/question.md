# Question

Solve this question on: `terminal`

The platform team publishes the `TeamEnvironment` API through the CRD `teamenvironments.platform.starfleet.io`. Today the CRD has one version, `v1alpha1`, and the `outpost` team keeps two objects in it: `alpha` and `beta`. The platform team now releases the stable version `v1`. The scripts of the `outpost` team still use `v1alpha1`, so that version must keep working for now. No object may be lost.

Change the CRD and the objects. When you finish, these must be true:

- The CRD lists exactly two versions: `v1alpha1` and `v1`. Both are served. `v1` is the storage version and `v1alpha1` is not. The conversion strategy is `None`.
- `v1` has the same schema as `v1alpha1`: `spec.team` and `spec.size` are required, `spec.size` is one of `small`, `medium` or `large`, `spec.replicas` is an integer from `0` to `5` with the default `1`, and `status` holds `readyReplicas` and `phase`. Both versions reject bad input, such as `size: huge`, `replicas: 9` or an unknown field.
- `v1alpha1` is deprecated. Its `deprecationWarning` is `platform.starfleet.io/v1alpha1 TeamEnvironment is deprecated; use platform.starfleet.io/v1`. A `kubectl get` through `v1alpha1` prints that warning. A `kubectl get` through `v1` prints none.
- The objects `alpha` and `beta` in `outpost` are still the original objects, with their original `spec`. Both are readable through `v1` and through `v1alpha1` with the same data.
- A new object `gamma` exists in `outpost`, created with `apiVersion: platform.starfleet.io/v1`. Its `spec` is team `outpost`, size `large` and `4` replicas.

Do not delete the CRD or the objects to start again. Do not use `x-kubernetes-preserve-unknown-fields` to avoid writing the schema.
