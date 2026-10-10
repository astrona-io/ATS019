# Read An Operator's Reconcile Loop

<!-- astrona:playground -->
> [!NOTE]
> This module has a playground — a throwaway environment to run the commands in.
> ```bash
> astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-020/module-01/playground
> ```

<!-- TODO(build): opening framing — what this module settles, and the contrast that sharpens its boundary. -->

## Learning objectives

- Name the controller, CRDs and RBAC objects an operator installs, from the cluster
- Trace a custom resource to the objects its controller created through ownerReferences
- Read status.conditions and compare observedGeneration with metadata.generation to judge whether the controller has acted
- Find why a reconcile failed from conditions, events and the controller's logs
- Show that the controller restores an owned object that was changed or deleted by hand

## Before you start

<!-- TODO(build): assumed knowledge, and what the playground already provides. -->

## Outline

<!-- TODO(build): each beat below becomes a section of this module (or a deep-dive part via /astrona-course-deep-dive). Delete this Outline section once written. -->

- What an operator installs - CRDs, a controller Deployment, a ServiceAccount and RBAC
- The reconcile loop - desired state, actual state, act, write status
- Conditions, reasons and observedGeneration - reading status like a controller writes it
- Owned objects and drift - what the controller puts back

## Diagrams planned

<!-- TODO(build): mermaid `sequence` — User applies a Prometheus resource, the Prometheus Operator watches it, creates a StatefulSet, Service and Secrets, then writes status conditions -->
<!-- TODO(build): mermaid `flowchart` — The reconcile loop - watch event, read desired, read actual, act, update status, requeue -->

<!-- playground provides: kind cluster (Kubernetes 1.35) with the Prometheus Operator 0.94.1 installed from its bundle in `default`. In namespace `starfleet`, a ServiceAccount `prometheus` with RBAC and a `Prometheus` resource `starfleet` (one replica, small memory request) that is Available, plus a second `Prometheus` resource `broken` that references a ServiceAccount that does not exist, so its pods are never created and its conditions say why. The `scout` Deployment and Service run in `starfleet` with a ServiceMonitor. -->

<!-- module section-020/module-01 (Module 1) — stub written by /astrona-course-domain-scaffold, prose written by /astrona-course-domain-build. -->
