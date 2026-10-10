# Version A CRD And Enable Subresources - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-019-playground-010-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with the
`TeamEnvironment` CustomResourceDefinition served only as `v1alpha1`, plus two
objects in `outpost`. The learner adds a `v1` version and enables the `status`
and `scale` subresources. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-019-playground-010-02
```

`astrona destroy` takes the environment name (`metadata.name` =
`ats-019-playground-010-02`), not the config path. `astrona submit` and
`astrona test` do not apply - there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `bootstrap/seed.sh` | Creates the namespaces, CRD and starting objects |
| `docs/overview.md` | What the environment contains and ideas to try |
