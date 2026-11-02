# Prerequisites

- `kubectl` 1.35 on your `PATH`.
- A cluster. The lab needs no add-ons and no outbound internet access.
- The namespace `starfleet` with the ConfigMaps `probe-settings` and `probe-cache`, the ServiceAccount, Role and RoleBinding `probe-cleanup`, and the suspended Job `probe-cleanup`. The lab creates them and requests the deletion of `probe-settings`.
