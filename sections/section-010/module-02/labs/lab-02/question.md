# Question

Solve this question on: `terminal`

The `TeamEnvironment` API of the platform team has one version, `v1`, and a controller will soon manage it. The controller needs its own endpoint to write status, so that a user who applies a manifest cannot overwrite it. The autoscaling tools of the platform team also need the standard scale endpoint. No controller runs yet, so you play its part and write the status by hand. The `outpost` team has two objects: `alpha` with 2 replicas and `beta` with 3 replicas.

Change the CRD, then the objects. When you finish, these must be true:

- The `v1` version of the CRD `teamenvironments.platform.starfleet.io` enables the `status` subresource.
- The `v1` version enables the `scale` subresource. `specReplicasPath` is `.spec.replicas` and `statusReplicasPath` is `.status.readyReplicas`.
- The `status` of `alpha` has `readyReplicas: 2` and `phase: Ready`.
- `beta` is scaled to `4` replicas with `kubectl scale`, and its `status` has `readyReplicas: 4` and `phase: Ready`.
- A normal write (an apply, or a patch without `--subresource=status`) does not change `status`. The scale endpoint of `alpha` returns `2` for both the desired and the observed replicas, and the scale endpoint of `beta` returns `4` for both.
- The schema still limits `spec.replicas` to the range `0` to `5`.

Do not delete the CRD or the objects to start again. Do not weaken the schema.
