---
estimated_duration: 20m
---

# Define A Platform API With An XRD Lab

- **ID:** ATS019-030-02-LAB-01
- **Slug:** ats-019-lab-030-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona hands-on lab, graded

Crossplane 2.4.2, `provider-kubernetes` 1.4.1 and
`function-patch-and-transform` 0.11.0 run in a single-node kind cluster on
Kubernetes 1.35.8. No platform API exists. The learner writes a
CompositeResourceDefinition (XRD) for a namespaced `ProbeEnvironment` API,
proves that it fills in defaults and refuses bad input, and creates one valid
request. The cluster needs outbound internet, because Crossplane pulls the
packages from `xpkg.crossplane.io`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-02/labs/lab-01
astrona submit -c sections/section-030/module-02/labs/lab-01
astrona destroy ats-019-lab-030-02
```

## Prove it (authors)

```sh
astrona test -c sections/section-030/module-02/labs/lab-01
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition: runtime, bootstrap, testing and validation |
| `prerequisites.md` | What the learner needs first |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `bootstrap/` | Installs Crossplane, the provider and the function |
| `manifests/` | Crossplane manifest, packages and the access manifest (`ClusterProviderConfig`, Role) |
| `solution/` | Reference XRD and request, applied only by `astrona test` |
| `testing/` | Helper that waits for the generated CRD |
| `validation/` | One script per check |

## Checks

| Script | What it proves |
| --- | --- |
| `validate-xrd-definition.sh` | The XRD has the right name, group, kind, scope and version, and is `Established` |
| `validate-valid-request-defaults.sh` | Server-side dry runs accept valid requests and fill in `tier: dev` and `instances: 2` |
| `validate-invalid-requests-refused.sh` | Server-side dry runs refuse a missing owner, bad numbers, a bad tier and an unknown field |
| `validate-stored-request.sh` | `first-probe` exists in `outpost` with the defaults applied |

The unknown-field case rejects the plausible wrong fix of setting
`x-kubernetes-preserve-unknown-fields: true` on the schema.
