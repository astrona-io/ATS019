---
estimated_duration: 30m
---

# Trigger A Provisioning Workflow From A Webhook — Lab

- **ID:** ATS019
- **Slug:** ats-019-lab-040-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona lab, graded

The learner builds the full path from a webhook request to a Workflow: an
EventBus, a webhook EventSource, a Role for the Sensor ServiceAccount, and a
Sensor with a data filter and a trigger parameter. The graders send real
events from `shuttle` and check what the cluster does.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-02/labs/lab-01
astrona destroy ats-019-lab-040-02
```

Authors can run a local copy with `astrona run -c sections/section-040/module-02/labs/lab-01` and prove the grading with
`astrona test -c sections/section-040/module-02/labs/lab-01`. The cluster needs outbound internet access.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition: pinned runtime, bootstrap, reference solution and graders |
| `prerequisites.md`, `question.md`, `solution.md` | Learner documents |
| `bootstrap/01-install-argo.sh` | Installs Argo Workflows 4.1.5 and Argo Events 1.9.11 |
| `manifests/starfleet-base.yaml` | `shuttle`, ServiceAccounts, step-result Role and the WorkflowTemplate. No EventBus, EventSource or Sensor |
| `solution/` | Reference end state, applied only by `astrona test` |
| `testing/wait-ready.sh` | Waits for the EventSource and Sensor pods during `astrona test` |
| `validation/validate-*.sh` | Five behaviour checks, 20 points each |

## What the graders check

1. `validate-01-eventsource.sh`: the EventBus, the EventSource and its Service exist, `POST /provision` returns `200`, `POST /other` and `GET /provision` do not.
2. `validate-02-sensor-rbac.sh`: `operate-workflow-sa` can create Workflows and has no wildcard, no Secret access and no Deployment access.
3. `validate-03-workflow-from-event.sh`: an event with a random team name starts a Workflow named `provision-environment-*` that has that team as its `team` parameter.
4. `validate-04-filter.sh`: tier `premium` starts a Workflow and tier `trial` does not.
5. `validate-05-workflow-succeeds.sh`: that Workflow ends as `Succeeded`.

The wrong fixes it rejects: `cluster-admin` or a wildcard for the Sensor
(check 2), a fixed team name in the Sensor (check 3) and no filter (check 4).
