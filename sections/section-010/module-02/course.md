# Version A CRD And Enable Subresources

<!-- astrona:playground -->
> [!NOTE]
> This module has a playground — a throwaway environment to run the commands in.
> ```bash
> astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-010/module-02/playground
> ```

<!-- TODO(build): opening framing — what this module settles, and the contrast that sharpens its boundary. -->

## Learning objectives

- Add a second version to a CRD and choose which version is served and which is the storage version
- Read which version an object is stored in from status.storedVersions
- Mark a version deprecated and read the warning kubectl prints
- Enable the status subresource and show that a spec update cannot change status
- Enable the scale subresource and scale a custom resource with kubectl scale

## Before you start

<!-- TODO(build): assumed knowledge, and what the playground already provides. -->

## Outline

<!-- TODO(build): each beat below becomes a section of this module (or a deep-dive part via /astrona-course-deep-dive). Delete this Outline section once written. -->

- Why platform APIs need versions - served, storage and deprecated
- Conversion without a webhook - what None conversion keeps and loses
- The status subresource - spec and status written by different actors
- The scale subresource - specReplicasPath, statusReplicasPath and kubectl scale

## Diagrams planned

<!-- TODO(build): mermaid `flowchart` — A v1alpha1 client and a v1 client reading the same object, with the API server converting to and from the storage version -->
<!-- TODO(build): mermaid `sequence` — User updates spec through the main endpoint while a controller writes status through the /status subresource -->

<!-- playground provides: kind cluster (Kubernetes 1.35) with no add-ons. The TeamEnvironment CRD is installed with a full schema in one version only (v1alpha1), with two TeamEnvironment objects already stored in v1alpha1 in namespace `outpost`. No status or scale subresource is enabled yet. A v1 schema file that renames nothing (so None conversion is safe) is provided for the reader to add. No controller runs; the reader acts as the controller with kubectl patch --subresource=status. -->

<!-- module section-010/module-02 (Module 2) — stub written by /astrona-course-domain-scaffold, prose written by /astrona-course-domain-build. -->
