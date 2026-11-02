# Question

Solve this question on: `terminal`

## Scenario

The `outpost` team no longer wants the platform API object `scout-env`, but its
`scout` workload must keep running and answering requests. The `TeamEnvironment`
`scout-env` in `outpost` is `Ready` and owns a Deployment, a Service and two
`Object` resources. You are the platform engineer. Delete the request and keep
the workload.

## Tasks

1. **Delete the request.** The `TeamEnvironment` `scout-env` in the namespace
   `outpost` must no longer exist.

2. **Keep the workload.** The original Deployment `scout` and the original
   Service `scout` in `outpost` must still exist. A copy that you create by hand
   does not count.

3. **Keep the composed Objects.** The two original `Object` resources in
   `outpost` must remain, and they must have no owner reference.

4. **Prove that the workload answers.** A request from the `shuttle` pod to
   `http://scout:9898` must return the HTTP status code `200`.

## Rules

- Do not delete the `Object` resources. Deleting an `Object` deletes the
  Deployment or the Service it manages.
- Do not delete the ConfigMap `lab-baseline` in the namespace `starfleet`.
- Do not recreate the Deployment or the Service by hand.
