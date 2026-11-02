# Prerequisites

- `kubectl` 1.35 on your `PATH`.
- A cluster with outbound internet access. Crossplane pulls the provider package from `xpkg.crossplane.io`.
- Crossplane 2.4.2 and `provider-kubernetes` 1.4.1, healthy. The lab installs them. The start can take a few minutes.
- The ProviderConfig `in-cluster`, the Object `scout`, the Role and the RoleBinding in the namespace `outpost`. The lab creates them.
