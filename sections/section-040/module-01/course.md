# Run Provisioning Steps With Argo Workflows

<!-- astrona:playground -->
> [!NOTE]
> This module has a playground — a throwaway environment to run the commands in.
> ```bash
> astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-01/playground
> ```

<!-- TODO(build): opening framing — what this module settles, and the contrast that sharpens its boundary. -->

## Learning objectives

- Write a WorkflowTemplate with input parameters, steps and a DAG of dependent tasks
- Submit a Workflow from a WorkflowTemplate with the argo CLI and override a parameter
- Give a workflow a ServiceAccount with only the RBAC its steps need, and diagnose a step that fails on permissions
- Read a workflow's phase, node status and step logs to find the failing step
- Use a resource template step to create a custom resource and wait for a success condition

## Before you start

<!-- TODO(build): assumed knowledge, and what the playground already provides. -->

## Outline

<!-- TODO(build): each beat below becomes a section of this module (or a deep-dive part via /astrona-course-deep-dive). Delete this Outline section once written. -->

- What Argo Workflows runs - one pod per step, and the workflow controller
- WorkflowTemplate, parameters, steps and DAG
- The workflow ServiceAccount and RBAC
- Resource steps - creating a platform API object and waiting for Ready
- Reading a failed workflow from the CLI and the user interface

## Diagrams planned

<!-- TODO(build): mermaid `flowchart` — DAG of a provisioning workflow - validate request, create TeamEnvironment, wait for Ready, smoke-test scout, notify -->
<!-- TODO(build): mermaid `sequence` — argo submit creates a Workflow, the workflow controller starts a pod per step, each step reports back, the Workflow reaches Succeeded -->

<!-- playground provides: kind cluster (Kubernetes 1.35) with Argo Workflows 4.1.5 installed in namespace `argo` with the server in auth-mode server and the `argo` CLI on the path. Namespace `starfleet` has a ServiceAccount `provisioner` with deliberately too few permissions. The TeamEnvironment CRD is installed (plain CRD, no controller), so resource steps can create objects and the reader sets status by hand with kubectl patch --subresource=status to satisfy a success condition. Crossplane is not installed, to keep memory low. -->

<!-- module section-040/module-01 (Module 1) — stub written by /astrona-course-domain-scaffold, prose written by /astrona-course-domain-build. -->
