# Question

Solve this question on: `terminal`

## Scenario

The `outpost` team needs its `scout` web service. The platform team has already
built the `TeamEnvironment` platform API and a Composition for it, and the
`shuttle` client pod runs in the `outpost` namespace. You act as the tenant.
You must get the workload through the platform API. Do not create a Deployment
or a Service yourself.

## Tasks

1. **Request the environment.** In the namespace `outpost`, create a
   `TeamEnvironment` named `scout-env` with `spec.team` set to `outpost`,
   `spec.size` set to `medium` and `spec.replicas` set to `2`.

2. **Wait until the request works.** The `Synced` and `Ready` conditions of
   `scout-env` must both be `True`.

3. **Let Crossplane build the workload.** The request must list two composed
   `Object` resources, and both must be `Ready`.

4. **Check the Deployment.** The Deployment `scout` in `outpost` must run 2
   available replicas, and its pods must carry the label `team` with the value
   `outpost`.

5. **Prove that the workload answers.** A request from the `shuttle` pod to
   `http://scout:9898` must return the HTTP status code `200`.
