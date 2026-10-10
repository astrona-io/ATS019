# Manage Deletion With Finalizers And Owner References

<!-- astrona:playground -->
> [!NOTE]
> This module has a playground — a throwaway environment to run the commands in.
> ```bash
> astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-020/module-02/playground
> ```

<!-- TODO(build): opening framing — what this module settles, and the contrast that sharpens its boundary. -->

## Learning objectives

- Predict which dependent objects the garbage collector deletes when an owner is deleted
- Choose between foreground, background and orphan cascading deletion with kubectl delete --cascade
- Explain why an object with a finalizer stays in Terminating and which controller must remove the finalizer
- Diagnose an object stuck in Terminating and fix the cause instead of removing the finalizer by hand

## Before you start

<!-- TODO(build): assumed knowledge, and what the playground already provides. -->

## Outline

<!-- TODO(build): each beat below becomes a section of this module (or a deep-dive part via /astrona-course-deep-dive). Delete this Outline section once written. -->

- ownerReferences and the garbage collector - who deletes the children
- Cascading deletion modes and when a platform team wants each one
- Finalizers - cleanup before delete, and deletionTimestamp
- Stuck in Terminating - finding the missing controller, and why patching the finalizer away is the last resort

## Diagrams planned

<!-- TODO(build): mermaid `state` — Lifecycle of an object with a finalizer - Active, deletionTimestamp set (Terminating), finalizer removed, deleted -->

<!-- playground provides: kind cluster (Kubernetes 1.35) with the Prometheus Operator 0.94.1 installed and a `Prometheus` resource `starfleet` that owns its StatefulSet, Service and Secrets. Namespace `starfleet` also has a ConfigMap `scout-settings` that carries a custom finalizer `platform.starfleet.io/cleanup` with no controller to remove it, so deleting it leaves it in Terminating on purpose. The TeamEnvironment CRD is installed so the reader can add ownerReferences between custom resources and ConfigMaps by hand. -->

<!-- module section-020/module-02 (Module 2) — stub written by /astrona-course-domain-scaffold, prose written by /astrona-course-domain-build. -->
