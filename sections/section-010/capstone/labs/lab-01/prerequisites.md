# Prerequisites

- `kubectl` 1.35 on your `PATH`.
- A single-node `kind` cluster on Kubernetes 1.35. The lab creates it. It needs no add-ons and no internet access.
- The namespaces `starfleet` and `outpost`. The lab creates them.
- A CRD named `databases.platform.starfleet.io` with one version, `v1alpha1`, and a weak schema. The lab creates it.
- Two `Database` objects in `outpost`, `orders-db` and `billing-db`, stored as `v1alpha1`. The lab creates them.
- No controller runs in the cluster. You write status by hand, as a controller would.
