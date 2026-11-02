# Prerequisites

- `kubectl` 1.35 on your `PATH`.
- A single-node `kind` cluster. The lab creates it. No add-ons and no outbound internet access are needed.
- The namespaces `starfleet` and `outpost`. The lab creates them.
- The CRD `teamenvironments.platform.starfleet.io`, served and stored only as `v1alpha1`, with no subresources. The lab creates it.
- The objects `alpha` (small, 2 replicas) and `beta` (medium, 3 replicas) in `outpost`. The lab creates them.
