# Trigger Workflows From Events With Argo Events — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-019-playground-040-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — no grading

A single-node kind cluster runs Kubernetes 1.35.8, Argo Workflows 4.1.5 and
Argo Events 1.9.11. The namespace `starfleet` holds the client pod `shuttle`,
the WorkflowTemplate `provision-environment` (one input parameter, `team`) and
the ServiceAccount `operate-workflow-sa`, which has no permissions. No
EventBus, EventSource or Sensor exists at the start.

## Run it

```sh
astrona run -c .
astrona destroy ats-019-playground-040-02
```

The destroy command takes the environment name, not the directory path.
There is no submission or grading. The cluster needs outbound internet access:
the bootstrap downloads both release manifests from GitHub.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Pinned runtime, three preloaded images and readiness checks |
| `bootstrap/01-install-argo.sh` | Installs both release manifests (server-side apply) and waits for the CRDs and controllers |
| `manifests/starfleet-base.yaml` | `shuttle`, the ServiceAccounts, the Role for step results and the WorkflowTemplate |
| `docs/overview.md` | Starting state and practice tasks (the only learner page) |

Initialization runs before the manifests. The `waitFor` checks run after both,
and wait for the two controllers and `shuttle`.
