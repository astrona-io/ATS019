---
estimated_duration: 40m
---

# Deliver Self-Service Environment Provisioning — Capstone

- **ID:** ATS019
- **Slug:** ats-019-capstone-040
- **Author:** Paris Nakita Kejser
- **Type:** Astrona capstone lab, graded

The learner finishes a self-service path from a webhook order to a Ready
`TeamEnvironment`: tenant and ServiceAccount RBAC, a WorkflowTemplate that
creates the custom resource and waits for it, an EventSource endpoint, and a
Sensor with a data filter and a trigger parameter. The graders send real
orders from `shuttle`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/capstone/labs/lab-01
astrona destroy ats-019-capstone-040
```

Authors can run a local copy with `astrona run -c sections/section-040/capstone/labs/lab-01` and prove the grading with
`astrona test -c sections/section-040/capstone/labs/lab-01`. The cluster needs outbound internet access.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition: pinned runtime, bootstrap, reference solution and graders |
| `prerequisites.md`, `question.md`, `solution.md` | Learner documents |
| `bootstrap/01-install-crossplane.sh`, `02-install-platform-api.sh` | Crossplane 2.4.2, the provider, the function, the XRD and the Composition |
| `bootstrap/03-install-argo.sh` | Argo Workflows 4.1.5 and Argo Events 1.9.11 |
| `manifests/platform/` | The `TeamEnvironment` API. The Composition sets `minReadySeconds: 20` and a readiness check |
| `manifests/starfleet-base.yaml`, `outpost-base.yaml` | Namespaces, `shuttle` pods and the two ServiceAccounts |
| `manifests/events-start.yaml` | EventBus, EventSource and Sensor, broken in four places |
| `solution/` | Reference end state, applied only by `astrona test` |
| `testing/wait-ready.sh` | Waits for the EventSource and Sensor pods during `astrona test` |
| `validation/validate-*.sh` | Seven behaviour checks |

## What the graders check

1. `validate-01-tenant-rbac.sh` (15): the group `outpost-team` can create, get, list and watch `teamenvironments` in `outpost` and nothing more. A second member must also be allowed.
2. `validate-02-provisioner-rbac.sh` (10): `provisioner` has the same four verbs in `outpost` and nothing more, and keeps its step-result rights.
3. `validate-03-template-shape.sh` (10): the WorkflowTemplate has the ServiceAccount, the parameter, a `create` step with a `successCondition` and a manifest that uses the parameter.
4. `validate-04-webhook.sh` (10): `POST /provision` returns `200`, `POST /other` and `GET /provision` do not.
5. `validate-05-sensor-rbac.sh` (10): `operate-workflow-sa` can create Workflows in `starfleet` and nothing more.
6. `validate-06-filter-and-mapping.sh` (15): a premium order starts a Workflow with the posted team, a trial order starts none.
7. `validate-07-order-ready.sh` (30): a standard order ends with a Succeeded Workflow, a Ready and Synced `TeamEnvironment` and `200` from `scout`.

The wrong fixes it rejects: binding the user instead of the group (1),
`cluster-admin` or a wildcard (1, 2, 5), a step without a `successCondition`
(3 and 7), a fixed team name in the Sensor (6), no filter (6), and creating the
`TeamEnvironment` by hand instead of through the Workflow (7).
