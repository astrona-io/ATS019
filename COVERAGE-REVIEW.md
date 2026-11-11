# Coverage review

The trace lesson now shows how to preserve the failing child's full condition before repair and use its UID to distinguish recovery from replacement. The coverage renderer includes both the singular validation.script and validation.scripts entries, so the tenant-permission and event checks are not omitted.

Two workflow labs previously reused the environment names of other modules. Their names are now ats-019-lab-040-01-02 and ats-019-lab-040-01-03; their published lab paths remain unchanged. Old local runs keep their old names until the learner destroys them.

Practical limits remain:

- The role-aggregation reading has no dedicated module lab; the tenant RBAC lab tests direct scoped grants.
- Crossplane providers and functions act on the local kind cluster, not a real cloud API.
- The finalizer exercise repairs a finite cleanup Job. It does not implement or prove the reliability of a continuously running custom controller.
- CRD versions use conversion None. Conversion webhooks and production storage migration are not established by serving two versions.
- Workflows and Events exercise local requests and webhooks. They do not cover a production event bus's durability or disaster recovery.

## Runtime choice

All current tasks use kind because their assessed behavior belongs to the Kubernetes API, controllers or cluster workloads. Separate environments keep different service meshes and policy configurations independent. Use QEMU for a future task that needs a separate kernel, VM boot behavior or a host service; none of these changes needs it.

## What verification establishes

The workflow checks registration and preparation order, then runs each selected environment on its own runner. A lab first requires API readiness and an explicit grader FAIL, applies its reference solution, runs all configured graders and tears down. The starting-state check stops at the first intentional rejection; it does not prove that every individual criterion fails initially. Shell errors, missing scripts, timeouts and inconsistent verdicts fail the test.

Playgrounds run bootstrap and readiness checks. A playground with testing/smoke.sh also runs that script. A successful playground start alone does not prove all learner commands. Network downloads, public registries and chart repositories remain external dependencies. Consult the PR's latest workflow for actual runtime results; this review and the generated map are not passing test reports.

## Readings without a module-lab link

These remain visible in the reverse map. Some are supporting concepts or integrated in a section capstone; none is claimed as an independently graded skill merely because it appears in a reading.

- [course-02-aggregate-platform-api-permissions](sections/section-040/module-03/course-02-aggregate-platform-api-permissions.md)
