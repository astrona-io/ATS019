# Design A CRD Schema That Validates Input — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-019-playground-010-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with no
add-ons. `bootstrap/seed.sh` creates the namespaces `starfleet` and
`outpost`, the `TeamEnvironment` CRD with a weak schema (`spec` keeps any
field), and three objects in `outpost`: `alpha` (valid), `beta` (misspelled
`replcas`) and `gamma` (size `huge`, 50 replicas, contact `nobody`).
Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-019-playground-010-01
```

`astrona destroy` takes the environment name (`metadata.name` =
`ats-019-playground-010-01`), not the config path. `astrona submit` and
`astrona test` do not apply — there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime and bootstrap only) |
| `bootstrap/seed.sh` | Namespaces, the weak CRD and the three starting objects |
| `docs/overview.md` | What the environment contains and ideas to try |
