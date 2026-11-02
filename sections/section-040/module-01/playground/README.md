# Run Provisioning Steps With Argo Workflows — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-019-playground-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — no grading

A single-node kind cluster runs Kubernetes 1.35.8 and Argo Workflows 4.1.5
(the workflow controller and the Argo server, both in the namespace `argo`).
The namespaces `starfleet` and `outpost` exist. The ServiceAccount
`provisioner` in `starfleet` may report step results but has no permission in
`outpost`. The `TeamEnvironment` CRD is installed without a controller.

## Run it

```sh
astrona run -c .
astrona destroy ats-019-playground-040-01
```

The destroy command takes the environment name, not the directory path.
There is no submission or grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Pinned runtime, preloaded images and readiness checks |
| `bootstrap/01-install-argo-workflows.sh` | Installs Argo Workflows from the release manifest and downloads the `argo` tool to `~/.astrona/bin` |
| `manifests/lab-start.yaml` | Namespaces, the `provisioner` ServiceAccount, the executor Role and the `TeamEnvironment` CRD |
| `docs/overview.md` | Starting state and practice tasks |

Initialization runs before the manifests. The `waitFor` checks run after both
and wait for the two Argo Deployments and the CRD.

## Notes for authors

- The course pages assume `provisioner` can already create and patch
  `workflowtaskresults` in `starfleet`. The Role `workflow-executor` gives
  that to `provisioner` and to the `default` ServiceAccount. The `default`
  ServiceAccount needs it for the first workflows, which set no
  ServiceAccount.
- Nothing is installed for Crossplane, Argo Events, Argo CD or Gitea.
- The `argo` tool is downloaded for the machine that runs `astrona run`. It
  is optional: every step also works with `kubectl`.
