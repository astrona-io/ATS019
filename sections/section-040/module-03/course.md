# Offer Self-Service Through Git And Scoped RBAC

<!-- astrona:playground -->
> [!NOTE]
> This module has a playground — a throwaway environment to run the commands in.
> ```bash
> astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-03/playground
> ```

<!-- TODO(build): opening framing — what this module settles, and the contrast that sharpens its boundary. -->

## Learning objectives

- Design a request flow where a tenant adds a composite resource manifest to a Git repository and Argo CD applies it
- Write a Role and RoleBinding that let a tenant group create and read only the platform API kind in its own namespace
- Aggregate the platform API's permissions into the built-in edit and view ClusterRoles with an aggregation label
- Prove the tenant can request a TeamEnvironment but cannot create Deployments or read Secrets, with kubectl auth can-i --as
- Trace a Git request through Argo CD sync to a Ready composite resource

## Before you start

<!-- TODO(build): assumed knowledge, and what the playground already provides. -->

## Outline

<!-- TODO(build): each beat below becomes a section of this module (or a deep-dive part via /astrona-course-deep-dive). Delete this Outline section once written. -->

- What self-service means on a platform - a request API, not cluster access
- RBAC for a platform API - Roles, ClusterRole aggregation and auth can-i
- Requests through Git - Gitea repository, an Argo CD Application per tenant
- Following a request from commit to Ready

## Diagrams planned

<!-- TODO(build): mermaid `flowchart` — Tenant commits a TeamEnvironment to Gitea, Argo CD syncs it into outpost, Crossplane composes it, status flows back to the tenant -->

<!-- playground provides: kind cluster (Kubernetes 1.35) with Gitea 28.1.0 in namespace `gitea` (user `platform`, organisation `starfleet`, repository `outpost-requests` seeded with an empty `requests/` folder), Argo CD 3.5.4 with one Application pointing at that repository, and Crossplane 2.4.2 with provider-kubernetes, function-patch-and-transform and the TeamEnvironment XRD and Composition installed. A tenant user `outpost-dev` (group `outpost-team`) is set up for impersonation and has no RBAC yet. This is the heaviest playground in the course; no Argo Workflows. Needs outbound internet. -->

<!-- module section-040/module-03 (Module 3) — stub written by /astrona-course-domain-scaffold, prose written by /astrona-course-domain-build. -->
