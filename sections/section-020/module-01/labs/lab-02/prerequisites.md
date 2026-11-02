# Prerequisites

- `kubectl` 1.35 on your `PATH`.
- A cluster with outbound internet access. The lab downloads the Prometheus Operator bundle.
- The Prometheus Operator 0.94.1 in the namespace `default`. The lab installs it.
- The `scout` workload, the ServiceAccount `prometheus` with read RBAC and the `Prometheus` resource `tenant` in the namespace `outpost`. The lab creates them.
