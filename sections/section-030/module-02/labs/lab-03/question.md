# Question

Solve this question on: `terminal`

## Scenario

The tenant team `drifter` in the namespace `outpost` created the request
`outpost-env`, a `TeamEnvironment` with `team: drifter` and `replicas: 2`.
The platform team's Composition `teamenvironment` should create the `scout`
Deployment and Service for it. A request from the `shuttle` Deployment to
`http://scout:9898` does not return `200`. The tenant cannot change the
Composition. You, the platform engineer, must find out why and repair it.

## Tasks

1. **Find the fault in the Composition.** Read the conditions and the events of
   `outpost-env`. Repair the Composition `teamenvironment` so that it runs.
   It stays in `Pipeline` mode and uses the installed Function
   `function-patch-and-transform`.

2. **Reach a healthy request.** `outpost-env` reports `Synced` `True` and
   `Ready` `True`, and it owns two composed `Object` resources, one for the
   Deployment and one for the Service.

3. **Make the Service reach the pods.** After task 1 the Service may still send
   traffic nowhere. Repair the cause in the Composition. The Service `scout`
   must select the pods of the Deployment `scout` and must have at least one
   endpoint.

4. **Prove the workload.** A request from the `shuttle` Deployment to
   `http://scout:9898` returns `200`.

5. **Keep the request.** Repair the Composition only. Do not delete or replace
   `outpost-env`. Do not point it at another Composition. Do not create or edit
   the Deployment or the Service by hand.
