# Question

Solve this question on: `terminal`

## Scenario

The platform team on the `starfleet` side wants tenant teams to ask for a
probe environment with one small object. The tenant team `drifter` works in
the namespace `outpost`. Crossplane 2.4.2 is installed and healthy. No platform
API exists yet. You write the API definition. No Composition is needed.

## Tasks

1. **Define the API.** Create a CompositeResourceDefinition named
   `probeenvironments.platform.starfleet.io` with `apiVersion:
   apiextensions.crossplane.io/v2`. Use `scope: Namespaced`, group
   `platform.starfleet.io`, kind `ProbeEnvironment` and plural
   `probeenvironments`. Define one version, `v1alpha1`, that is served and
   referenceable. Wait until the XRD is `Established`.

2. **Describe `spec` in the schema.** The `spec` object has these fields:

   | Field | Type | Rules |
   | --- | --- | --- |
   | `owner` | string | Required |
   | `tier` | string | Only `dev`, `staging` or `prod`; default `dev` |
   | `instances` | integer | From `1` to `5`; default `2` |
   | `contactEmail` | string | Optional |

   A request that sets only `owner` must be stored with `tier: dev` and
   `instances: 2`.

3. **Refuse bad requests.** The API server must refuse a `ProbeEnvironment`
   that has no `owner`, `instances: 0`, `instances: 6`, `tier: test`, or any
   field that the schema does not declare, for example `colour`. Fix this in the
   schema. Do not switch off checking for unknown fields.

4. **Create one request.** In the namespace `outpost`, create a
   `ProbeEnvironment` named `first-probe` that sets only `owner: drifter`.
   Check that the stored object shows `tier: dev` and `instances: 2`.
