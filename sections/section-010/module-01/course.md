# Design A CRD Schema That Validates Input

<!-- astrona:playground -->
> [!NOTE]
> This module has a playground — a throwaway environment to run the commands in.
> ```bash
> astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-010/module-01/playground
> ```

<!-- TODO(build): opening framing — what this module settles, and the contrast that sharpens its boundary. -->

## Learning objectives

- Write a CustomResourceDefinition in apiextensions.k8s.io/v1 with a structural openAPIV3Schema for a platform service
- Mark fields as required and constrain them with enum, minimum, maximum and pattern
- Set default values and predict which unknown fields the API server prunes
- Write a CEL rule in x-kubernetes-validations, including a transition rule that uses oldSelf
- Add additionalPrinterColumns and a shortName so kubectl get shows the important fields
- Prove a rule works by applying a custom resource the API server must reject

## Before you start

<!-- TODO(build): assumed knowledge, and what the playground already provides. -->

## Outline

<!-- TODO(build): each beat below becomes a section of this module (or a deep-dive part via /astrona-course-deep-dive). Delete this Outline section once written. -->

- What a CRD adds to the API server, and what happens on kubectl apply of a custom resource
- The structural schema - types, required, enum, ranges and patterns
- Defaulting and pruning - what the API server writes back and what it drops
- CEL validation rules - self, oldSelf, messages and when a rule runs
- Printer columns, short names and categories for a usable kubectl get

## Diagrams planned

<!-- TODO(build): mermaid `flowchart` — Path of a create request through the API server - decode, prune, default, schema validation, CEL rules, then etcd -->

<!-- playground provides: kind cluster (Kubernetes 1.35) with no add-ons. A starter CRD `teamenvironments.platform.starfleet.io` (kind TeamEnvironment) is applied with a deliberately weak schema (x-kubernetes-preserve-unknown-fields on spec, no required fields, no printer columns), plus three example manifests on disk: a valid TeamEnvironment, one with a typo in a field name, and one with an out-of-range replica count, all of which the weak schema accepts. Namespaces `starfleet` and `outpost` exist. No controller acts on the CRD, so status stays empty on purpose. -->

<!-- module section-010/module-01 (Module 1) — stub written by /astrona-course-domain-scaffold, prose written by /astrona-course-domain-build. -->
