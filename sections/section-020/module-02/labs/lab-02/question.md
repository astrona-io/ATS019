# Question

Solve this question on: `terminal`

The platform team asked for the removal of the ConfigMap `probe-settings` in the namespace `starfleet` a long time ago. The delete request was accepted, but the ConfigMap is still there. It carries the finalizer `platform.starfleet.io/cleanup`.

The cleanup contract for this finalizer has two steps, in this order: delete the ConfigMap `probe-cache` in `starfleet`, then remove the finalizer from `probe-settings`. The worker for this contract is the Job `probe-cleanup` in `starfleet`. It runs as the ServiceAccount `probe-cleanup`, and its permissions come from the Role and RoleBinding of the same name. Find out why the cleanup does not run and why it could not finish, and restore it.

When you finish, these must be true:

- The Job `probe-cleanup` has the condition `Complete` with status `True`.
- The ConfigMaps `probe-cache` and `probe-settings` no longer exist in `starfleet`.
- The ServiceAccount `probe-cleanup` may `get`, `list` and `watch` both ConfigMaps by name, `patch` `probe-settings`, and `delete` `probe-cache`.
- That is all it may do. It must not be able to delete `probe-settings`, to delete other ConfigMaps or all ConfigMaps in `starfleet`, to act in other namespaces, to read Secrets, or to do everything (`cluster-admin`).

Do not remove the finalizer yourself and do not delete `probe-cache` yourself: the worker must do both. Do not change the Job template.
