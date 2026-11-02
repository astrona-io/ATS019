# Install A Crossplane Provider And ProviderConfig — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-019-playground-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — no grading

A single-node kind cluster runs Kubernetes 1.35.8 and Crossplane 2.4.2 in the
namespace `crossplane-system`. The namespaces `starfleet` and `outpost` exist
and are empty. No provider is installed: the reader installs
`provider-kubernetes`, creates a ProviderConfig and a managed resource, and
repairs the RBAC the provider is missing.

## Run it

```sh
astrona run -c .
astrona destroy ats-019-playground-030-01
```

The destroy command takes the environment name, not the directory path.
There is no submission or grading. The cluster needs outbound internet access,
because Crossplane pulls provider packages from `xpkg.crossplane.io`.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Pinned runtime (`kindest/node:v1.35.8`) and the Crossplane image to preload |
| `bootstrap/01-install-crossplane.sh` | Creates the three namespaces, applies the Crossplane manifest and waits for the package manager CRDs |
| `manifests/crossplane-2.4.2.yaml` | Crossplane 2.4.2 rendered once from the official chart, so only `kubectl` is needed |
| `docs/overview.md` | Starting state and open practice tasks |

The playground deliberately installs no provider, no ProviderConfig and no
RBAC. Those objects are the material of the module.
