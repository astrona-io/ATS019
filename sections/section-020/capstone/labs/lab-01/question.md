# Question

Solve this question on: `terminal`

This is the Section 020 capstone: one integrated operators task, no step-by-step guidance.

The `outpost` team reports three problems in its namespace `outpost`. The Prometheus Operator 0.94.1 runs in the namespace `default` and must not be changed.

First, the `Prometheus` resource `outpost-metrics` never starts. Second, deleting the `TeamEnvironment` `scout-env` (`platform.starfleet.io/v1alpha1`) would leave its ConfigMaps behind, because they have no owner reference. Third, the ConfigMap `scout-settings` was deleted but is still in the cluster. The platform team prepared a cleanup Job named `scout-cleanup` for it. Find each cause and repair it.

## Tasks

1. **Reconcile the Prometheus resource.** The `Prometheus` resource `outpost-metrics` must report the conditions `Reconciled` and `Available`, both with status `True`. Repair the original resource: do not delete and create it again. Keep `spec.additionalScrapeConfigs`, which names the key `jobs.yaml` in the Secret `extra-scrape`. Use the ServiceAccount `prometheus` that already exists in `outpost` and already has the access Prometheus needs. Do not create the StatefulSet or the pod yourself, and do not widen the access of any ServiceAccount.

2. **Link the environment ConfigMaps to their owner.** The ConfigMaps `scout-env-settings` and `scout-env-limits` belong to the `TeamEnvironment` `scout-env`. Deleting `scout-env` must delete both of them. Each must have exactly one owner reference, to `scout-env`, with the UID of the existing object. The ConfigMap `shared-notes` has the same label (`team: outpost`) but does not belong to `scout-env`: it must stay without an owner. Do not delete or recreate `scout-env` or any ConfigMap.

3. **Finish the stuck deletion.** The ConfigMap `scout-settings` in `outpost` has the finalizer `platform.starfleet.io/cleanup`. The cleanup contract is to delete the ConfigMap `scout-cache` first and then release the finalizer. The Job `scout-cleanup` runs as the ServiceAccount `scout-cleanup`. When you finish, `scout-settings` and `scout-cache` must not exist, and the Job `scout-cleanup` must be `Complete`. The cleanup must run through the Job: do not remove the finalizer yourself and do not delete `scout-cache` yourself. The ServiceAccount `scout-cleanup` may delete only the ConfigMap `scout-cache` and patch only the ConfigMap `scout-settings`. It must not get access to other ConfigMaps, to other kinds, or to `cluster-admin`. The ConfigMap `shared-notes` must still exist at the end.
