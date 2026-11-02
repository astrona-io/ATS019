# Trigger Workflows From Events With Argo Events

A platform often must start work when something happens, not when a person runs a command. A request arrives from a tenant team, and the platform must provision an environment for it. Argo Events turns an incoming event, such as an HTTP request, into an action in the cluster, such as a new Workflow.

Argo Events has three objects that work together. An EventSource receives events from the outside. An EventBus carries events inside the cluster. A Sensor watches the EventBus, checks each event against its rules, and runs a trigger when the rules match. Together they connect a request from a tenant to a Workflow that does the work.

The module has four parts. **EventBus And Webhook EventSource** installs the transport and the receiver and sends the first event. **A Sensor That Submits A Workflow** connects an event to a WorkflowTemplate and fixes the permission that blocks the first trigger. **Filters And Parameter Mapping** keeps unwanted events out and passes a value from the event body into the Workflow. **Follow An Event That Went Nowhere** gives a fixed order of checks for an event that starts nothing.

<!-- astrona:playground -->

## Learning objectives

After this module you can:

- Install an EventBus and a webhook EventSource, and send the EventSource an event with `curl` from the `shuttle` pod.
- Write a Sensor with a dependency and a trigger that submits a Workflow from a WorkflowTemplate.
- Pass a value from the event body into a Workflow parameter.
- Diagnose an event that does not start a Workflow by reading the status and logs of the EventSource and the Sensor.

## Before you start

You need Kubernetes basics: namespaces, Services, ServiceAccounts, and the commands `kubectl get`, `kubectl apply`, `kubectl logs` and `kubectl exec`. You should know that a Workflow is an Argo Workflows object that runs steps in pods, and that a WorkflowTemplate is a stored Workflow definition with input parameters.

Write each example file in a new, empty folder on your machine and run every command from that folder. Your playground runs Kubernetes 1.35.8 in a single-node `kind` cluster, with Argo Workflows 4.1.5 and Argo Events 1.9.11 already installed.

| Namespace | What is in it |
| --- | --- |
| `starfleet` | The WorkflowTemplate `provision-environment`, which has one input parameter named `team`. The client pod `shuttle`. A ServiceAccount for the Sensor that cannot create Workflows yet. |

No EventBus, EventSource or Sensor exists at the start. You create them in the first parts.
