---
estimated_duration: 20m
---

# Find Why An Event Starts No Workflow — Lab

- **ID:** ATS019
- **Slug:** ats-019-lab-040-02-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona lab, graded (troubleshooting)

The lab starts broken on purpose. The EventBus, the EventSource, the Role and
the Sensor exist, and every request returns `200`, but no event starts a
Workflow. The fault is in the Sensor: its data filter reads the path `tier`
instead of `body.tier`. Never fix this in the bootstrap.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-02/labs/lab-02
astrona submit --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-02/labs/lab-02
astrona destroy ats-019-lab-040-02-02
```

Authors can run a local copy with `astrona run -c sections/section-040/module-02/labs/lab-02` and prove the grading with
`astrona test -c sections/section-040/module-02/labs/lab-02`. The cluster needs outbound internet access.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition: pinned runtime, bootstrap, reference solution and graders |
| `prerequisites.md`, `question.md`, `solution.md` | Learner documents |
| `bootstrap/01-install-argo.sh` | Installs Argo Workflows 4.1.5 and Argo Events 1.9.11 |
| `manifests/starfleet-base.yaml` | `shuttle`, ServiceAccounts, step-result Role and the WorkflowTemplate |
| `manifests/events-start.yaml` | The faulty start state: EventBus, EventSource, Role and the Sensor with the wrong filter path |
| `solution/` | The corrected Sensor, applied only by `astrona test` |
| `testing/wait-ready.sh` | Waits for the replaced Sensor pod during `astrona test` |
| `validation/validate-*.sh` | Five behaviour checks, 20 points each |

## What the graders check

1. `validate-01-fault-fixed-in-sensor.sh`: the EventBus and the EventSource keep their design (`POST /provision`, port `12000`) and the Sensor keeps its dependency and ServiceAccount.
2. `validate-02-event-starts-workflow.sh`: an event with tier `standard` and a random team name starts a Workflow with that team.
3. `validate-03-filter-still-drops.sh`: tier `premium` starts a Workflow and tier `trial` still does not.
4. `validate-04-rbac-not-widened.sh`: `operate-workflow-sa` still can create Workflows and has no wildcard and no Secret access.
5. `validate-05-workflow-succeeds.sh`: the Workflow ends as `Succeeded`.

The wrong fixes it rejects: deleting the filter (check 3), changing the
EventSource to fit the Sensor (check 1) and widening the Sensor permissions
(check 4).
