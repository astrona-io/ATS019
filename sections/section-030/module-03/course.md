# Provision And Trace A Composite Resource

<!-- astrona:playground -->
> [!NOTE]
> This module has a playground — a throwaway environment to run the commands in.
> ```bash
> astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-03/playground
> ```

<!-- TODO(build): opening framing — what this module settles, and the contrast that sharpens its boundary. -->

## Learning objectives

- Request a composite resource in a tenant namespace and follow it to Ready
- Trace a composite resource to every composed and managed resource with crossplane resource trace
- Read Synced and Ready conditions on the composite resource and its composed resources to find the failing one
- Diagnose a Composition that references a missing function or patches a field that does not exist
- Choose between deleting a composite resource and orphaning its composed resources

## Before you start

<!-- TODO(build): assumed knowledge, and what the playground already provides. -->

## Outline

<!-- TODO(build): each beat below becomes a section of this module (or a deep-dive part via /astrona-course-deep-dive). Delete this Outline section once written. -->

- Requesting through the API - a tenant applies one small object
- Tracing the tree - from composite resource to managed resources to real objects
- Reading failure - which condition on which object says what went wrong
- Lifecycle - updates flowing down, deletion and what happens to composed resources

## Diagrams planned

<!-- TODO(build): mermaid `sequence` — Tenant applies a TeamEnvironment, Crossplane runs the function pipeline, provider-kubernetes creates objects, conditions flow back up to Ready -->
<!-- TODO(build): mermaid `state` — Composite resource conditions over time - created, Synced True, waiting for composed resources, Ready True, or ReconcileError -->

<!-- playground provides: kind cluster (Kubernetes 1.35) with Crossplane 2.4.2, provider-kubernetes 1.4.1 with a working ProviderConfig, and function-patch-and-transform 0.11.0. A working TeamEnvironment XRD and Composition are installed. A second Composition `teamenvironment-with-cache` deliberately references a function that is not installed and patches a misspelled field, so a composite resource that selects it stays not Ready. Namespace `outpost` has one Ready TeamEnvironment. Needs outbound internet. -->

<!-- module section-030/module-03 (Module 3) — stub written by /astrona-course-domain-scaffold, prose written by /astrona-course-domain-build. -->
