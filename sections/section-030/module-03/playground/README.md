# Provision And Trace A Composite Resource — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-019-playground-030-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — no grading

A single-node kind cluster runs Kubernetes 1.35.8 and Crossplane 2.4.2 with
provider-kubernetes 1.4.1 and function-patch-and-transform 0.11.0. The
`TeamEnvironment` XRD, a working Composition (`teamenvironment`), a Composition
that is broken on purpose (`teamenvironment-with-cache`) and a `shuttle` client
pod in `outpost` are in place. No `TeamEnvironment` exists at the start. The
crossplane CLI 2.4.1 is downloaded into the lab work folder.

## Run it

```sh
astrona run -c .
astrona destroy ats-019-playground-030-03
```

The destroy command takes the environment name, not the directory path.
There is no submission or grading. The playground needs outbound internet:
Crossplane pulls its provider and function from `xpkg.crossplane.io`.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Pinned runtime, preloaded images, bootstrap order and readiness check |
| `bootstrap/01-install-crossplane.sh` | Installs Crossplane 2.4.2 from the rendered manifest |
| `bootstrap/02-install-platform-api.sh` | Installs the provider and function, the ProviderConfig, the RBAC and the XRD |
| `bootstrap/03-install-crossplane-cli.sh` | Downloads the crossplane CLI 2.4.1; a failure only warns |
| `manifests/crossplane-2.4.2.yaml` | Crossplane rendered once from the official chart |
| `manifests/*.yaml` | Packages, ProviderConfig, RBAC, XRD, both Compositions and `shuttle` |
| `docs/overview.md` | What is in the box and practice tasks |

Initialization runs before the manifests. The XRD must exist before the
Compositions, so the init scripts apply it and the manifests apply the
Compositions and `shuttle`. The XRD sets `teamenvironment` as its default
Composition, because two Compositions serve the same type.
