# Define A Platform API With An XRD And Composition

<!-- astrona:playground -->
> [!NOTE]
> This module has a playground — a throwaway environment to run the commands in.
> ```bash
> astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-02/playground
> ```

<!-- TODO(build): opening framing — what this module settles, and the contrast that sharpens its boundary. -->

## Learning objectives

- Write a CompositeResourceDefinition in apiextensions.crossplane.io/v2 with a namespaced scope and a validated schema
- Install function-patch-and-transform and reference it from a Composition in Pipeline mode
- Compose several in-cluster resources (Namespace, ResourceQuota, Deployment, Service) from one composite resource
- Patch values from the composite resource spec into composed resources and write fields back to status
- Preview what a Composition will produce with crossplane composition render before applying it

## Before you start

<!-- TODO(build): assumed knowledge, and what the playground already provides. -->

## Outline

<!-- TODO(build): each beat below becomes a section of this module (or a deep-dive part via /astrona-course-deep-dive). Delete this Outline section once written. -->

- From CRD to XRD - what Crossplane adds on top of a schema
- Compositions as a pipeline of functions
- Patch and transform - from the XR spec to composed resources and back to status
- Rendering locally to check a Composition before it reaches the cluster

## Diagrams planned

<!-- TODO(build): mermaid `flowchart` — XRD defines the TeamEnvironment API, a Composition pipeline runs function-patch-and-transform, which returns Namespace, ResourceQuota, Deployment and Service -->
<!-- TODO(build): mermaid `er` — Relationships between XRD, Composition, composite resource and composed resources, with cardinality -->

<!-- playground provides: kind cluster (Kubernetes 1.35) with Crossplane 2.4.2, provider-kubernetes 1.4.1 with a working ProviderConfig `in-cluster` and enough RBAC, and function-patch-and-transform 0.11.0 installed and healthy. No XRD or Composition exists yet. The `scout` image is pre-pulled. The `crossplane` CLI and a local container runtime are available for `crossplane composition render`. Needs outbound internet. -->

<!-- module section-030/module-02 (Module 2) — stub written by /astrona-course-domain-scaffold, prose written by /astrona-course-domain-build. -->
