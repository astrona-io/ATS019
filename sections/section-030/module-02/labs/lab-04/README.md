---
estimated_duration: 25m
---

# Extend A Native Composition Without Recreating Requests Lab

- **ID:** ATS019-030-02-LAB-04
- **Slug:** ats-019-lab-030-02-04
- **Author:** Paris Nakita Kejser
- **Type:** Astrona hands-on lab, graded (build)

Consume an existing namespaced XRD, then extend its partial Composition with
a native ClusterIP Service. Crossplane 2.4.2 and
`function-patch-and-transform` 0.11.0 run on Kubernetes 1.35.8. No provider is
needed. The existing Composition creates a headless Service and a one-replica
StatefulSet with `ghcr.io/stefanprodan/podinfo:6.15.0`. That image includes
`curl`, which the task uses for requests from a Pod.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-02/labs/lab-04
astrona submit --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-02/labs/lab-04
astrona destroy ats-019-lab-030-02-04
```

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Runtime, bootstrap, reference solution and grading |
| `prerequisites.md` | Required knowledge and initial state |
| `question.md` | Exam-style task |
| `solution.md` | Walkthrough with incremental submission |
| `bootstrap/` | Installs Crossplane and the function, creates the partial setup and records identities |
| `manifests/` | Pinned installation, function, permissions, XRD, partial Composition and original XR |
| `solution/` | Complete Composition, new XR and reference apply script |
| `testing/` | Waits for both Services and ready requests |
| `validation/` | Four live checks and a shared shell helper |

## Checks

| Check | What it proves |
| --- | --- |
| `tenant-request` | The new request consumes the supplied API and owns a ready native workload |
| `composition-extended` | The Service template uses the requested patches and readiness check; the original templates stay intact |
| `existing-request-updated` | The original request adopts the updated revision and owns its new Service; original object identities remain |
| `services-reach-pods` | Both Services select ready StatefulSet Pods and return HTTP 200 |

Every check fails on the untouched start state. Bootstrap saves the original
request, StatefulSet and headless Service UIDs, the active revision, and the
two original resource templates in immutable ConfigMap `starfleet/lab-state`.
The solution runs only through the `testing` stage, never during bootstrap.

Static checks only: built without booting on 2026-11-04. No runtime result is
claimed. Run `astrona validate -c sections/section-030/module-02/labs/lab-04`
for configuration and local-file validation.
