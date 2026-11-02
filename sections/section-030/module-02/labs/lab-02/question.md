# Question

Solve this question on: `terminal`

## Scenario

The tenant team `drifter` in the namespace `outpost` created the request
`outpost-env`. It is a `TeamEnvironment` with `team: drifter` and
`replicas: 2`. The platform team's Composition `teamenvironment` creates the
`scout` Deployment and Service, but the Deployment runs one replica and the
request does not show how many replicas are available. The `shuttle` client
Deployment in `outpost` is available for tests.

## Tasks

1. **Honour the replica count.** Change the Composition `teamenvironment` so
   that `spec.replicas` of the request sets `spec.replicas` of the Deployment
   `scout`. When the request changes to `replicas: 3`, the Deployment must
   change to 3 replicas. When the request changes back to 2, the Deployment
   must change back to 2.

2. **Report the result.** Change the same Composition so that the number of
   available replicas of the Deployment is written into
   `status.availableReplicas` of the request. With two replicas running,
   `kubectl -n outpost get teamenvironment outpost-env` must show `2` in that
   field.

3. **Keep the request and the Composition.** Fix the problem in the Composition
   `teamenvironment`, which stays in `Pipeline` mode with
   `function-patch-and-transform`. Do not delete or replace `outpost-env`. Do not
   edit the Deployment or the Service by hand. Do not point the request at
   another Composition.

4. **Prove the workload.** A request from the `shuttle` Deployment to
   `http://scout:9898` returns `200`, and the pods of `scout` carry the label
   `team: drifter`.
