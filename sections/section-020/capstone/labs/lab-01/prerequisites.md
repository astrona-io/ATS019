# Prerequisites

- `kubectl` 1.35 on your `PATH`.
- A cluster with outbound internet access. The start downloads the Prometheus Operator 0.94.1 bundle from GitHub.
- The Prometheus Operator, its CustomResourceDefinitions (CRDs) and the `TeamEnvironment` CRD. The lab installs them.
- The namespace `outpost` with the objects described in the question. The lab creates them. The start takes a few minutes.
