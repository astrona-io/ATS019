# Install A Crossplane Provider And ProviderConfig

<!-- astrona:playground -->
> [!NOTE]
> This module has a playground — a throwaway environment to run the commands in.
> ```bash
> astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-01/playground
> ```

<!-- TODO(build): opening framing — what this module settles, and the contrast that sharpens its boundary. -->

## Learning objectives

- Confirm Crossplane's pods, CRDs and package manager are healthy before installing anything on top
- Install a provider package and read INSTALLED and HEALTHY from kubectl get providers
- Configure a ProviderConfig for provider-kubernetes that uses an injected identity, and grant it the RBAC it needs
- Create a managed resource directly and read its Synced and Ready conditions
- Diagnose a managed resource that is not Synced because of missing provider permissions

## Before you start

<!-- TODO(build): assumed knowledge, and what the playground already provides. -->

## Outline

<!-- TODO(build): each beat below becomes a section of this module (or a deep-dive part via /astrona-course-deep-dive). Delete this Outline section once written. -->

- What Crossplane adds - packages, providers, managed resources and the control loop
- A running Crossplane and a provider package, and what HEALTHY means
- ProviderConfig and credentials - injected identity versus a Secret
- Managed resources - Synced versus Ready, and reading a failed sync

## Diagrams planned

<!-- TODO(build): mermaid `flowchart` — Crossplane core, the provider-kubernetes package and controller, its ProviderConfig, and the managed Object it reconciles into a real ConfigMap -->

<!-- playground provides: kind cluster (Kubernetes 1.35) with Crossplane 2.4.2 pre-installed in `crossplane-system` and the `crossplane` CLI on the path. No provider is installed yet; a provider manifest for provider-kubernetes 1.4.1 is ready to apply. The provider's service account deliberately has no extra RBAC, so the first managed Object fails to sync until the reader grants permissions. Needs outbound internet to pull from xpkg.crossplane.io. -->

<!-- module section-030/module-01 (Module 1) — stub written by /astrona-course-domain-scaffold, prose written by /astrona-course-domain-build. -->
