# Prerequisites

You need `kubectl` and `git` on your machine, and you need to know what an Argo
CD `Application` and `AppProject` are. The cluster is a single-node `kind`
cluster on Kubernetes 1.35.8 with outbound internet access.

At the start:

- Crossplane 2.4.2 runs with `provider-kubernetes`, `function-patch-and-transform`, the `TeamEnvironment` XRD and a working Composition. The Composition creates a Deployment and a Service named `scout` in the namespace of the request.
- Gitea, an in-cluster Git server, hosts the public repository `starfleet/outpost-requests`. Its `requests/` folder is empty. The user is `platform` and the password is `platform-secret-19`.
- Argo CD 3.5.4 runs in the namespace `argocd`.
- The Deployment `shuttle` in `outpost` is a client pod with `curl`.
