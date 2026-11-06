# Question

Solve this question on: `terminal`

## Scenario

The `outpost` team requested the `TeamEnvironment` named `scout-env`, but it
is not ready. Crossplane and its command-line interface (CLI) are installed.
The CLI binary is `/workspace/bin/crossplane`. The Composition
`teamenvironment` creates two managed `Object` resources,
which `provider-kubernetes` uses to apply the `scout` Deployment and Service.
One managed resource cannot reconcile.

## Tasks

1. **Record the diagnosis before repairing it.** Use
   `crossplane resource trace` with wide output to find the failing composed
   resource. Create a ConfigMap named `trace-report` in `outpost`. Set its
   data keys `kind` and `name` to that resource's exact kind and generated
   name. Set `reason` and `message` to the exact reason and full message of
   its failing `Synced` condition. Preserve these original values after repair.
2. **Repair the cause.** Fix the failing resource's provider configuration
   reference in Composition `teamenvironment` to use the existing
   `ClusterProviderConfig` named `in-cluster`. Keep both composed `Object`
   resources and the original request, with `spec.team: outpost` and its
   selected Composition unchanged. Make the request and both composed
   resources report `Synced: True` and `Ready: True`, with Service `scout`
   present in `outpost`.

Do not replace the request or the failing composed resource. Do not create
a replacement provider configuration or edit the captured starting state in
ConfigMap `trace-baseline` in `starfleet`.
