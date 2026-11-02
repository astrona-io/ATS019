# Question

Solve this question on: `terminal`

This is the Section 040 capstone — one integrated self-service provisioning task, no step-by-step guidance.

## Scenario

The `drifter` team works in the namespace `outpost`. It must get an environment without a platform engineer starting the work by hand. A request arrives as an HTTP `POST`, an Argo Workflow files a `TeamEnvironment` (API group `platform.starfleet.io`), and Crossplane builds the Deployment `scout` and the Service `scout` in `outpost`.

The cluster is ready. Crossplane, the `TeamEnvironment` API and its Composition work. Argo Workflows and Argo Events run. The namespace `starfleet` has the client pod `shuttle`, the ServiceAccount `provisioner` (the identity of the Workflow steps), the ServiceAccount `operate-workflow-sa` (the identity of the Sensor) and the Argo Events objects EventBus `default`, EventSource `provision` and Sensor `provision`. The namespace `outpost` has its own `shuttle` pod. The user `outpost-dev` is a member of the group `outpost-team`.

The order path is not finished. Do all of the following.

1. In the namespace `outpost`, give the group `outpost-team` the rights to file and follow requests. It must be able to `create`, `get`, `list` and `watch` `teamenvironments`. Bind the group, so that every member gets the rights. Members must not be able to update, patch or delete a `TeamEnvironment`, must not be able to create or get Deployments, Services, Pods, Secrets or ConfigMaps, and must not be able to create a `TeamEnvironment` in `starfleet` or `default`.

2. In the namespace `outpost`, give the ServiceAccount `provisioner` of the namespace `starfleet` the rights to `create`, `get`, `list` and `watch` `teamenvironments`. It must not be able to update, patch or delete them, to change the `status` subresource, to create Deployments, Services or Secrets, or to create anything in `default`. Do not use a wildcard or `cluster-admin`. Do not remove the step-result rights that `provisioner` already has in `starfleet`.

3. In the namespace `starfleet`, create a WorkflowTemplate named `request-environment`. It runs as the ServiceAccount `provisioner` and has one input parameter named `team`. It has one resource step with `action: create` that creates a `TeamEnvironment` in the namespace `outpost`. The name and `spec.team` of that `TeamEnvironment` must be the value of the parameter `team`. The step must not end until the environment has available replicas: the `TeamEnvironment` shows the number in `status.availableReplicas`. Pods count as available 20 seconds after they are ready, so a step that does not wait ends too early.

4. Repair the EventSource `provision` so that it accepts a `POST` request at `http://provision-eventsource-svc.starfleet.svc:12000/provision`. Other paths and other methods must not return `200`.

5. In the namespace `starfleet`, give the ServiceAccount `operate-workflow-sa` only the right to `create` Workflows in `starfleet`. It must have no right in `outpost`, no wildcard, no access to Secrets or Deployments, and no right to create a `TeamEnvironment`.

6. Repair the Sensor `provision`. It must accept an event only when `body.tier` is `standard` or `premium`. A request with the tier `trial` must start no Workflow. For an accepted event, it must submit a Workflow from the WorkflowTemplate `request-environment` with `workflowTemplateRef`. The name of the Workflow starts with `request-environment-`. The parameter `team` of the Workflow is the value of `body.team` from the event.

7. Prove the whole path. A request such as `{"team":"drifter","tier":"standard"}`, sent from `shuttle` in `starfleet` with the header `Content-Type: application/json`, must end with a `Succeeded` Workflow, a `TeamEnvironment` named `drifter` in `outpost` that is `Ready` and `Synced`, and a Service `scout` in `outpost` that answers `200` on port `9898` to a request from `shuttle` in `outpost`. The grader uses a team name of its own and removes every `TeamEnvironment` in `outpost` before it starts. Only one environment can run in `outpost` at a time, because the Deployment and the Service are both named `scout`.
