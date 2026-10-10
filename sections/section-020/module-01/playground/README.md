# Read An Operator's Reconcile Loop - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-019-playground-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with the
Prometheus Operator 0.94.1 installed from its `bundle.yaml` in `default`. In
`starfleet`: the `scout` and `shuttle` workloads, a ServiceMonitor for
`scout`, the ServiceAccount `prometheus` with read RBAC, a working
`Prometheus` resource `starfleet` and a `Prometheus` resource `broken` that
names a ServiceAccount that does not exist. The operator, config reloader,
Prometheus, podinfo and curl images are preloaded. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-019-playground-020-01
```

`astrona destroy` takes the environment name (`metadata.name` =
`ats-019-playground-020-01`), not the config path. `astrona submit` and
`astrona test` do not apply - there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, bootstrap steps) |
| `bootstrap/01-install-operator.sh` | Installs the Prometheus Operator bundle and waits for the Deployment |
| `bootstrap/02-seed.sh` | Creates `scout`, `shuttle`, the ServiceMonitor, RBAC and the two `Prometheus` resources |
| `docs/overview.md` | What the environment contains and ideas to try |
