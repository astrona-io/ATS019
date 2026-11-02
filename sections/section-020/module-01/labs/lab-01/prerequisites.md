# Prerequisites

- `kubectl` 1.35 on your `PATH`.
- A cluster with outbound internet access. The lab downloads the Prometheus Operator bundle.
- The Prometheus Operator 0.94.1 in the namespace `default`. The lab installs it.
- The `Prometheus` resource `starfleet` in the namespace `starfleet`, with its ServiceAccount and RBAC. The lab creates them.
