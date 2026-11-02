# Summary

Argo Events connects an incoming event to an action in the cluster with three objects. The EventSource receives events from outside, here as HTTP requests on a webhook with a port, an endpoint and a method. The EventBus carries events inside the namespace, and every EventSource and Sensor needs one, named `default` unless the object says otherwise. The Sensor reads events from the EventBus and runs triggers.

A Sensor has dependencies and triggers. A dependency names an EventSource and an event, and both names must match exactly. A trigger of type `argoWorkflow` with `operation: submit` creates a Workflow, and a `workflowTemplateRef` points it at a stored WorkflowTemplate. The Sensor pod creates the Workflow with its own ServiceAccount, so that ServiceAccount needs a Role that allows `create` on `workflows`.

A data filter decides which events a dependency accepts, and it reads paths such as `body.tier` from the webhook data. A trigger parameter copies a value, selected with `dataKey`, into a field of the trigger resource, selected with `dest`. Together they let a request choose its own input to the Workflow.

When an event starts nothing, follow it in order. Check the HTTP status of the request, then the status and log of the EventSource, then the status and log of the Sensor, and last the Workflow. A `200` response proves only that the EventSource accepted the request. Each failure leaves evidence in a status code, a condition message or a log line.

- EventSource: receives the event and publishes it to the EventBus.
- Sensor: filters events, maps data and runs the trigger.
- `forbidden` in the Sensor log: the Sensor ServiceAccount lacks permission.
- A filtered event returns `200` and starts no Workflow.

<!-- astrona:playground:destroy -->
