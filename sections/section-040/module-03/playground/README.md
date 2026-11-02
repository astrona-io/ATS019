# Offer Self-Service Through Git And Scoped RBAC — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-019-playground-040-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — no grading

A single-node kind cluster runs Kubernetes 1.35.8 with Crossplane 2.4.2,
`provider-kubernetes` 1.4.1 and `function-patch-and-transform` 0.11.0. The
`TeamEnvironment` XRD and its working Composition are applied. Gitea (plumbing)
hosts the public repository `starfleet/outpost-requests` with an empty
`requests/` folder. Argo CD 3.5.4 runs in `argocd` with one Application,
`outpost-requests`, still in the `default` project. The user `outpost-dev` in
the group `outpost-team` has no RBAC; the reader impersonates it with
`kubectl --as`.

## Run it

```sh
astrona run -c .
astrona destroy ats-019-playground-040-03
```

The destroy command takes the environment name, not the directory path.
There is no submission or grading. The cluster needs outbound internet.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Pinned runtime, preloaded images and readiness checks |
| `bootstrap/01-install-crossplane.sh` | Installs Crossplane and creates the `starfleet` and `outpost` namespaces |
| `bootstrap/02-install-platform-api.sh` | Installs the provider and function, then applies the RBAC, XRD and Composition |
| `bootstrap/03-install-gitea.sh` | Starts Gitea and seeds `starfleet/outpost-requests` |
| `bootstrap/04-install-argocd.sh` | Installs Argo CD from its release manifest |
| `manifests/crossplane-2.4.2.yaml` | Rendered Crossplane install (copy of the section 030 file) |
| `manifests/platform/` | Packages, ClusterProviderConfig, provider RBAC, XRD and Composition |
| `manifests/gitea.yaml` | Gitea Deployment, Service and the `gitea-platform` Secret |
| `manifests/application-outpost-requests.yaml` | Starting Argo CD Application |
| `manifests/shuttle.yaml` | Client pod used to send requests to `scout` |
| `docs/overview.md` | The only learner page |

The `platform` user's password is `platform-secret-19`. It is stored in the
Secret `gitea-platform` in `gitea`. Initialization scripts run before the
manifests, and the `waitFor` checks run last.
