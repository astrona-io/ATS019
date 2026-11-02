# Define A Platform API With An XRD And Composition — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-019-playground-030-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — no grading

A single-node kind cluster runs Kubernetes 1.35.8 and Crossplane 2.4.2 with
`provider-kubernetes` 1.4.1 and `function-patch-and-transform` 0.11.0. A
ClusterProviderConfig named `in-cluster` and a Role in `outpost` let the
provider create Deployments and Services. No XRD and no Composition exist: the
reader writes them. The cluster needs outbound internet, because Crossplane
pulls the packages from `xpkg.crossplane.io`.

## Run it

```sh
astrona run -c .
astrona destroy ats-019-playground-030-02
```

The destroy command takes the environment name, not the directory path.
There is no submission or grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Pinned runtime, preloaded images and readiness checks |
| `bootstrap/01-install-crossplane.sh` | Creates the namespaces and installs Crossplane |
| `bootstrap/02-install-packages.sh` | Installs the provider and the function, waits for them, then applies the access manifest |
| `manifests/crossplane-2.4.2.yaml` | Crossplane 2.4.2 rendered once from the official chart |
| `manifests/packages.yaml` | `DeploymentRuntimeConfig`, `Provider` and `Function` |
| `manifests/platform-access.yaml` | `ClusterProviderConfig` `in-cluster`, plus the Role and RoleBinding for the provider |
| `docs/overview.md` | Starting state, practice tasks and the Crossplane command line tool |

Initialization runs both scripts in order. The second script applies the access
manifest only after the provider has installed its CRDs. The `waitFor` checks
then confirm that the provider and the function are healthy.
