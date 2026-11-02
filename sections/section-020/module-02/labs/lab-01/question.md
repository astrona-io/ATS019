# Question

Solve this question on: `terminal`

The `outpost` team replaces its `TeamEnvironment` named `probe-env` with a new one named `probe-env-v2`, and retires the `TeamEnvironment` named `scout-env`. All objects are in the namespace `outpost`. No controller watches `TeamEnvironment` objects, so only Kubernetes itself removes dependent objects.

The ConfigMap `probe-data` is owned by `probe-env` and holds data that must survive. It must stay the same object: deleting it and creating a new one with the same name is not allowed. The ConfigMap `scout-config` is owned by `scout-env` and must go away together with it. The ConfigMap `scout-unowned` only shares the label `team: outpost` with the others. It has no owner and must stay untouched.

When you finish, these must be true:

- The `TeamEnvironment` `probe-env-v2` exists in `outpost` with `spec.team: outpost` and `spec.size: medium`.
- The ConfigMap `probe-data` is the original object, still has `data.mode: small`, and has exactly one owner reference. That reference points to the `TeamEnvironment` `probe-env-v2`, with its real UID.
- The `TeamEnvironment` `probe-env` no longer exists.
- The `TeamEnvironment` `scout-env` no longer exists, and the ConfigMap `scout-config` is gone because Kubernetes removed it as a dependent.
- The ConfigMap `scout-unowned` still exists with its label.

Do not delete `probe-data` or `scout-unowned`, and do not delete the ConfigMap `lab-baseline` in the namespace `default`. Do not use a label selector to delete objects.
