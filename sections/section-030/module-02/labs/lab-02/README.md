---
estimated_duration: 25m
---

# Patch A Composition To Honour Tenant Requests Lab

- **ID:** ATS019-030-02-LAB-02
- **Slug:** ats-019-lab-030-02-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona hands-on lab, graded

Crossplane 2.4.2, `provider-kubernetes` 1.4.1 and
`function-patch-and-transform` 0.11.0 run in a single-node kind cluster on
Kubernetes 1.35.8. The `TeamEnvironment` XRD, the Composition `teamenvironment`,
the request `outpost-env` and the client Deployment `shuttle` are applied at
the start. The Composition ignores `spec.replicas` and never writes status. The
learner adds the two patches. The cluster needs outbound internet.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-02/labs/lab-02
astrona submit -c sections/section-030/module-02/labs/lab-02
astrona destroy ats-019-lab-030-02-02
```

## Prove it (authors)

```sh
astrona test -c sections/section-030/module-02/labs/lab-02
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition: runtime, bootstrap, testing and validation |
| `prerequisites.md` | What the learner needs first |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `bootstrap/` | Installs Crossplane and the packages, then applies the start state |
| `manifests/` | Crossplane manifest, packages, access manifest, XRD, faulty Composition, request and `shuttle` |
| `solution/` | Reference Composition, applied only by `astrona test` |
| `testing/` | Helper that waits until the request is Synced and Ready |
| `validation/` | One script per check |

## Checks

| Script | What it proves |
| --- | --- |
| `validate-composition-integrity.sh` | The same request (same UID) still uses Composition `teamenvironment` and owns composed Objects |
| `validate-replicas-follow-request.sh` | The Deployment follows `spec.replicas` (2, then 3, then 2). A hard-coded number or a hand-edited Deployment fails |
| `validate-status-written-back.sh` | `status.availableReplicas` on the request equals the available replicas of the Deployment |
| `validate-service-answers.sh` | `shuttle` gets `200` from the Service and the pods carry `team: drifter` |

The grader changes `spec.replicas` of `outpost-env` to 3 and back to 2. It
leaves the request at 2 replicas.
