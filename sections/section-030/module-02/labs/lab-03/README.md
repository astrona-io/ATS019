---
estimated_duration: 30m
---

# Repair A Broken Composition Lab

- **ID:** ATS019-030-02-LAB-03
- **Slug:** ats-019-lab-030-02-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona hands-on lab, graded (troubleshooting)

Crossplane 2.4.2, `provider-kubernetes` 1.4.1 and
`function-patch-and-transform` 0.11.0 run in a single-node kind cluster on
Kubernetes 1.35.8. The `TeamEnvironment` XRD, the request `outpost-env` and the
client Deployment `shuttle` are applied at the start, together with a Composition
`teamenvironment` that has two faults. The first names a function that is not
installed (`function-patch-and-transfrom`). The second is hidden behind the
first: the Service selects `app: scouts` and so reaches no pod. The learner
finds both from the status of the request and from the Service. The cluster
needs outbound internet.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-02/labs/lab-03
astrona submit -c sections/section-030/module-02/labs/lab-03
astrona destroy ats-019-lab-030-02-03
```

## Prove it (authors)

```sh
astrona test -c sections/section-030/module-02/labs/lab-03
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition: runtime, bootstrap, testing and validation |
| `prerequisites.md` | What the learner needs first |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `bootstrap/` | Installs Crossplane and the packages, then applies the start state and records the UID of the request |
| `manifests/` | Crossplane manifest, packages, access manifest, XRD, the faulty Composition, request and `shuttle` |
| `solution/` | Reference Composition, applied only by `astrona test` |
| `testing/` | Helper that waits until the request is Synced and Ready |
| `validation/` | One script per check |

## Checks

| Script | What it proves |
| --- | --- |
| `validate-composition-repaired.sh` | The same request (same UID) uses Composition `teamenvironment`, which names the installed `function-patch-and-transform` |
| `validate-request-synced-ready.sh` | `outpost-env` is `Synced` and `Ready` and owns two composed Objects |
| `validate-service-selects-pods.sh` | The Service, its `Object` and the Composition all select `app: scout`, and the Service has endpoints |
| `validate-request-answers-200.sh` | `shuttle` gets `200` from `http://scout:9898` |

The checks reject deleting and recreating the request, creating a new
Composition and moving the request to it, and editing the Service by hand.
