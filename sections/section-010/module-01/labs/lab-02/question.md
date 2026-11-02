# Question

Solve this question on: `terminal`

The CRD `teamenvironments.platform.starfleet.io` (kind `TeamEnvironment`, version `v1alpha1`) already has a typed schema. It refuses a bad `size`, `replicas` and `contact`, and it sets `replicas` to `1` when the field is missing. Two business rules are still missing, and operators complain that `kubectl get` shows only a name and an age.

Change the existing CRD. Keep its name, kind, scope and version, keep the limits in the schema, and do not delete the `TeamEnvironment` `alpha` in `outpost`. `alpha` is `small` with 2 replicas.

When you finish, these must be true:

- A `TeamEnvironment` with `size: small` and more than 2 replicas is refused by the API server, on create and on update. A `small` object with 2 replicas or with no `replicas` is accepted. A `medium` object with 4 replicas and a `large` object with 5 replicas are accepted. Write this as a CEL rule on `spec`, not as a lower `maximum` on `replicas`.
- `spec.team` cannot be changed after creation. An update that changes `spec.team` is refused. An update that changes another field, or that sends the same team again, is accepted. A new object can have any valid team.
- `kubectl -n outpost get teamenv alpha` works and shows the columns `NAME`, `TEAM`, `SIZE`, `REPLICAS` and `AGE`, in this order, with the values of `.spec.team`, `.spec.size`, `.spec.replicas` and the creation time.
- `kubectl -n outpost get platform` lists the `TeamEnvironment` objects. The category is `platform`, not `all`.
- The schema must not use `x-kubernetes-preserve-unknown-fields`.
