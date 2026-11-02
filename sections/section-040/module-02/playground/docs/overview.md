# Overview: Trigger Workflows From Events With Argo Events (Playground)

This playground gives you a cluster where Argo Events can start Argo Workflows. An event is a small message that says something happened. Argo Events receives it, checks it, and starts a Workflow. There is nothing to submit and no grading.

## What's in the box

The single-node `kind` cluster runs Kubernetes 1.35.8 with Argo Workflows 4.1.5 and Argo Events 1.9.11. Argo Workflows runs the steps of a Workflow in pods. Argo Events has three objects: an EventSource receives events, an EventBus carries them inside the namespace, and a Sensor starts an action when an event matches.

| Namespace | Objects |
| --- | --- |
| `argo` | The Argo Workflows controller and the Argo server |
| `argo-events` | The Argo Events controller |
| `starfleet` | The client pod `shuttle` (image `curlimages/curl`) |
| `starfleet` | The WorkflowTemplate `provision-environment`, with one input parameter, `team` |
| `starfleet` | The ServiceAccount `provisioner`, which the Workflow pods use to report step results |
| `starfleet` | The ServiceAccount `operate-workflow-sa`, which has no Role yet |

No EventBus, EventSource or Sensor exists at the start. You create them in `starfleet`. The Argo Events controller needs a few minutes after the first EventBus to start its JetStream pods.

## Practice tasks

- Create an EventBus named `default`, then a webhook EventSource named `provision` with the endpoint `/provision` on port `12000`. Send a request from `shuttle` and read the EventSource log.
- Create a Sensor that submits a Workflow from `provision-environment`. Send an event and read the Sensor log until you find the `forbidden` error. Grant only `create` on `workflows` to `operate-workflow-sa`.
- Add a data filter on `body.tier` and a trigger parameter that copies `body.team` into the `team` parameter. Send one valid and one filtered event and compare the Workflows.
- Break the Sensor on purpose, for example with a wrong `eventName`, and follow the event through the request, the EventSource, the Sensor and the Workflow.
