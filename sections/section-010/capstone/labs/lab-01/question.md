# Question

Solve this question on: `terminal`

This is the Section 010 capstone: one integrated CRD task, no step-by-step guidance.

## Scenario

The platform team in `starfleet` offers a `Database` API to tenant teams. Today the CRD `databases.platform.starfleet.io` serves only `v1alpha1`. Its `spec` accepts any field, so a misspelled field or a database with 900 replicas is stored without a complaint. The `outpost` namespace already holds two objects, `orders-db` and `billing-db`. They must keep working: the same objects, with the same data, through both versions.

Publish the validated and versioned API by updating the existing CRD in place. Do not delete the CRD and do not recreate `orders-db` or `billing-db`. Do not use `x-kubernetes-preserve-unknown-fields: true` anywhere in the schema.

## Tasks

1. **Names.** Keep the group `platform.starfleet.io`, the kind `Database`, the plural `databases` and the scope `Namespaced`. Add the short name `db`.

2. **Two versions.** Serve both `v1alpha1` and `v1`. Make `v1` the storage version. Use conversion strategy `None`, and give both versions the same schema and the same rules, so a client on the old version cannot bypass them.

3. **Required fields.** An object needs a `spec`. Inside `spec`, `team` (text, 1 to 30 characters) and `engine` (text, one of `postgres` or `mysql`) are required.

4. **Limits and defaults.** `storageGB` is an integer from 1 to 500 and defaults to `10`. `replicas` is an integer from 1 to 5 and defaults to `1`. The API server must refuse unknown or misspelled fields, such as `replcas`.

5. **Three CEL rules.**
   - `storageGB` can grow or stay the same, but it cannot shrink.
   - `team` cannot change after the object is created.
   - An object with more than 1 replica needs `storageGB` of 20 or more.

6. **Deprecate the old version.** Mark `v1alpha1` as deprecated. Its warning text is exactly `platform.starfleet.io/v1alpha1 Database is deprecated; use platform.starfleet.io/v1`. Keep it served. Do not deprecate `v1`.

7. **Status subresource on `v1`.** Enable it. A write to the main endpoint must not change `status`, and a write to the status endpoint must not change `spec`. `status.readyReplicas` is an integer and `status.phase` is text.

8. **Scale subresource on `v1`.** Enable it so that `kubectl scale` changes `spec.replicas`, and the scale endpoint reports `status.readyReplicas` as the observed replicas.

9. **Printer columns on `v1`.** `kubectl get` shows these columns in this order after `NAME`: `ENGINE` (from `spec.engine`), `STORAGE` (from `spec.storageGB`), `REPLICAS` (from `spec.replicas`), `READY` (from `status.readyReplicas`) and `AGE`.

When you finish, `orders-db` and `billing-db` must be the original objects. They must still show `orders`, `postgres`, 50 GB and `billing`, `mysql`, 10 GB through `v1` and through `v1alpha1`.
