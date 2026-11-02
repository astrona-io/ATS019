# Prerequisites

- `kubectl` 1.35 on your `PATH`.
- A cluster with outbound internet access. Crossplane pulls the provider package from `xpkg.crossplane.io`.
- Crossplane 2.4.2 in the namespace `crossplane-system`. The lab installs it.
- The empty namespaces `starfleet` and `outpost`. The lab creates them.
- No provider is installed at the start.
