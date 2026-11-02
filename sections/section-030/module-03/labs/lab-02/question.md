# Question

Solve this question on: `terminal`

## Scenario

The `outpost` team asked for a `TeamEnvironment` named `scout-env`, with 2
replicas, but the `scout` workload does not work. The platform team changed the
Composition `teamenvironment` and the change broke it. You are the platform
engineer. Find the faults by tracing the request, and fix them in the
Composition. Do not change the request.

## Tasks

1. **Trace the request.** Use `kubectl` and the `crossplane resource trace`
   command to find which composed resource is not `Ready`, and read its
   conditions.

2. **Fix the Composition `teamenvironment`.** The faults are inside the
   Composition. Two things must be true afterwards:
   - The resource named `service` uses the ProviderConfig `in-cluster`.
   - The resource named `deployment` copies `spec.replicas` of the request to
     `spec.forProvider.manifest.spec.replicas`.

3. **Let the request recover.** The `TeamEnvironment` `scout-env` in `outpost`
   must keep `spec.team: outpost`, `spec.replicas: 2` and the Composition
   `teamenvironment`. Its `Synced` and `Ready` conditions must both be `True`.

4. **Check the workload.** The Deployment `scout` in `outpost` must run 2
   available replicas, and the Service `scout` must exist.

5. **Prove that the workload answers.** A request from the `shuttle` pod to
   `http://scout:9898` must return the HTTP status code `200`.

## Rules

- Do not create, edit or delete the Deployment, the Service or any `Object`
  resource by hand. Crossplane must create them from the Composition.
- Do not add a second ProviderConfig and do not widen the RBAC rules of the
  provider.
