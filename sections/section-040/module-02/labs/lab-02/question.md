# Question

Solve this question on: `terminal`

The `drifter` team in the `outpost` namespace sends provisioning requests to the platform. Every request returns `200`, but no environment is ever provisioned. The platform team set up the receiving side last week, and nobody can say what is wrong.

The namespace `starfleet` has an EventBus named `default`, a webhook EventSource named `provision`, a Sensor named `provision`, the WorkflowTemplate `provision-environment` with the input parameter `team`, and the pod `shuttle`. The Sensor runs as the ServiceAccount `operate-workflow-sa`, which already has a Role that allows it to create Workflows. The EventSource listens for `POST` on `http://provision-eventsource-svc.starfleet.svc:12000/provision`.

Do all of the following:

1. Find the component that breaks the path from the request to the Workflow. Read its status, its configuration and its log. Do not guess.
2. Fix the fault in the object that causes it. Do not change the other objects to fit the fault.
3. Prove the fix. A request such as `{"team":"drifter","tier":"standard"}`, sent from `shuttle` with the header `Content-Type: application/json`, must start a Workflow from `provision-environment` whose `team` parameter is `drifter`, and the Workflow must end as `Succeeded`.

The rules of the platform stay the same. Only the tiers `standard` and `premium` are accepted, and a request with the tier `trial` must start no Workflow. The ServiceAccount `operate-workflow-sa` must keep only the permission it already has.
