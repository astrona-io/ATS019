# Manage Deletion With Finalizers And Owner References — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-019-playground-020-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — no grading

A single-node kind cluster runs Kubernetes 1.35.8 and Prometheus Operator
0.94.1. The available Prometheus resource owns a StatefulSet, Service and
Secrets. The TeamEnvironment CRD has no controller. Two ConfigMaps and a
suspended cleanup Job let the reader diagnose a finalizer and restore cleanup.
The Job deletes scout-cache before removing scout-settings' finalizer.

## Run it

```sh
astrona run -c .
astrona destroy ats-019-playground-020-02
```

The destroy command takes the environment name, not the directory path.
There is no submission or grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Pinned runtime, four preloaded images and readiness checks |
| `bootstrap/01-install-operator.sh` | Installs the release bundle before manifests are applied |
| `manifests/lab-start.yaml` | Namespaces, Prometheus, the finalizer example and TeamEnvironment CRD |
| `manifests/cleanup-worker.yaml` | Cache ConfigMap, scoped permissions and suspended cleanup Job |
| `docs/overview.md` | Starting state, read-only helper functions and practice tasks |

Initialization runs before starting manifests. The waitFor checks run after
both, and wait for the operator Deployment and Available Prometheus resource.
The cleanup Job stays suspended until the reader starts it. Its first init
container waits for deletionTimestamp, its second deletes the cache, and its
main container removes only the expected finalizer after a JSON Patch test.
