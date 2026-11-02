# Question

Solve this question on: `terminal`

The `drifter` team in the `outpost` namespace must get an environment without a platform engineer starting the work by hand. The platform receives a request over HTTP and must start the Workflow that provisions the environment.

The cluster is ready. The namespace `starfleet` has the pod `shuttle` (a client pod with `curl`), the WorkflowTemplate `provision-environment` with one input parameter named `team`, and the ServiceAccount `operate-workflow-sa`, which has no permissions. No EventBus, EventSource or Sensor exists.

Do all of the following in the namespace `starfleet`:

1. Create an EventBus named `default`.
2. Create a webhook EventSource named `provision`. Its webhook is named `request`, listens on port `12000`, uses the endpoint `/provision` and accepts only the method `POST`. Make it reachable at `http://provision-eventsource-svc.starfleet.svc:12000/provision`.
3. Create a Sensor named `provision` that runs as the ServiceAccount `operate-workflow-sa`. It waits for the event `request` of the EventSource `provision`. The Sensor must accept an event only when `body.tier` is `standard` or `premium`.
4. When the Sensor accepts an event, it must submit a new Workflow from the WorkflowTemplate `provision-environment` with `workflowTemplateRef`. The Workflow name must start with `provision-environment-`. The `team` parameter of the Workflow must be the value of `body.team` from the event.
5. Give `operate-workflow-sa` only the permission it needs to create Workflows in `starfleet`. Do not give it `cluster-admin`, a wildcard, or access to Secrets.

A request such as `{"team":"outpost","tier":"standard"}`, sent with the header `Content-Type: application/json`, must start a Workflow that ends as `Succeeded`. A request with the tier `trial` must start no Workflow.
