# Coverage review

The review adds an independent aggregation lab and a playground procedure test. Both apply labelled ClusterRoles and verify editor/viewer rights, denied writes and namespace boundaries. The original narrow tenant Role lab remains separate.

The trace lesson now shows how to preserve the failing child's full condition before repair and use its UID to distinguish recovery from replacement. The coverage renderer includes both the singular validation.script and validation.scripts entries, so the tenant-permission and event checks are not omitted.

Two workflow labs previously reused the environment names of other modules. Their names are now ats-019-lab-040-01-02 and ats-019-lab-040-01-03; their published lab paths remain unchanged. Old local runs keep their old names until the learner destroys them.

Practical limits remain:

- Crossplane providers and functions act on the local kind cluster, not a real cloud API.
- The finalizer exercise repairs a finite cleanup Job. It does not implement or prove the reliability of a continuously running custom controller.
- CRD versions use conversion None. Conversion webhooks and production storage migration are not established by serving two versions.
- Workflows and Events exercise local requests and webhooks. They do not cover a production event bus's durability or disaster recovery.

## Runtime choice

All current tasks use kind because their assessed behavior belongs to the Kubernetes API, controllers or cluster workloads. Separate environments keep different service meshes and policy configurations independent. Use QEMU for a future task that needs a separate kernel, VM boot behavior or a host service; none of these changes needs it.

## What verification establishes

The workflow checks registration and preparation order, then runs each selected environment on its own runner. A lab first requires API readiness and an explicit grader FAIL, applies its reference solution, runs all configured graders and tears down. The starting-state check stops at the first intentional rejection; it does not prove that every individual criterion fails initially. Shell errors, missing scripts, timeouts and inconsistent verdicts fail the test.

Playgrounds run bootstrap and readiness checks. A playground with testing/smoke.sh also runs that script. A successful playground start alone does not prove all learner commands. Network downloads, public registries and chart repositories remain external dependencies. Consult the PR's latest workflow for actual runtime results; this review and the generated map are not passing test reports.

## Assessment and procedure checks

CI checks quiz registration, answer references, unique question IDs, declared counts and links to earlier readings. Playground procedure tests cover the named examples above; other playgrounds still prove only startup and declared readiness unless they contain their own smoke script. These checks do not establish every command in every lesson.

## Readings without a module-lab link

The generated reverse map in [LAB-COVERAGE.md](LAB-COVERAGE.md) lists the current supporting and capstone-only readings. A listed concept is not claimed as independently assessed without a lab link.
