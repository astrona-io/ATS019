# Trigger Workflows From Events With Argo Events

<!-- astrona:playground -->
> [!NOTE]
> This module has a playground — a throwaway environment to run the commands in.
> ```bash
> astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-02/playground
> ```

<!-- TODO(build): opening framing — what this module settles, and the contrast that sharpens its boundary. -->

## Learning objectives

- Install an EventBus and a webhook EventSource and send it an event with curl from shuttle
- Write a Sensor with a dependency and a trigger that submits a Workflow from a WorkflowTemplate
- Pass a value from the event payload into a workflow parameter
- Diagnose an event that does not start a workflow by reading EventSource and Sensor logs and status

## Before you start

<!-- TODO(build): assumed knowledge, and what the playground already provides. -->

## Outline

<!-- TODO(build): each beat below becomes a section of this module (or a deep-dive part via /astrona-course-deep-dive). Delete this Outline section once written. -->

- Event-driven provisioning - EventBus, EventSource, Sensor and trigger
- A webhook EventSource and a test event
- Sensor dependencies, filters and parameter mapping into a Workflow
- Following an event that went nowhere

## Diagrams planned

<!-- TODO(build): mermaid `sequence` — shuttle posts JSON to the webhook EventSource, the event goes through the EventBus, the Sensor matches it and submits a Workflow with a parameter from the payload -->

<!-- playground provides: kind cluster (Kubernetes 1.35) with Argo Workflows 4.1.5 and Argo Events 1.9.11 installed, and a working `provision-environment` WorkflowTemplate in `starfleet`. No EventBus, EventSource or Sensor exists yet. The `shuttle` pod runs in `starfleet`. The Sensor's ServiceAccount is created without permission to create Workflows, so the first trigger fails on purpose. -->

<!-- module section-040/module-02 (Module 2) — stub written by /astrona-course-domain-scaffold, prose written by /astrona-course-domain-build. -->
