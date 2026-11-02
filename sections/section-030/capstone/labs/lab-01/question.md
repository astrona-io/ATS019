# Question

Solve this question on: `terminal`

## Scenario

The platform team in `starfleet` must offer the tenant team in `outpost` a self-service
`TeamEnvironment` API. The tenant writes one small request. Crossplane creates the
`scout` workload from it. Crossplane 2.4.2 and the function `function-patch-and-transform`
are installed and healthy. `provider-kubernetes` is not installed. The `shuttle` client pod
runs in `outpost`. Build the platform API and use it as the tenant.

## Tasks

1. **Install the provider.** Install `provider-kubernetes` from the package
   `xpkg.crossplane.io/crossplane-contrib/provider-kubernetes:v1.4.1`. The provider pod must
   run under the ServiceAccount `provider-kubernetes` in `crossplane-system`, and it must
   start with the argument `--poll=30s`, so that it reads the status of the objects it manages
   every 30 seconds. Wait until the `Provider` is `Installed` and `Healthy`.

2. **Connect the provider to this cluster.** Create a `ClusterProviderConfig` named
   `in-cluster` (API group `kubernetes.m.crossplane.io`) that uses the injected identity.
   Create no other provider configuration.

3. **Grant the provider the access it needs.** The platform team started a Role and a
   RoleBinding for this ServiceAccount in `outpost`. The provider must be able to `get`,
   `create`, `update` and `delete` Deployments and Services in `outpost`. It must not gain
   more than that: no access to other namespaces, no access to all namespaces at once, no
   access to other kinds, and no `cluster-admin`.

4. **Define the API.** Create a CompositeResourceDefinition named
   `teamenvironments.platform.starfleet.io` with `apiVersion:
   apiextensions.crossplane.io/v2`, `scope: Namespaced`, group `platform.starfleet.io`,
   kind `TeamEnvironment` and plural `teamenvironments`. Define one version, `v1alpha1`,
   that is served and referenceable. Wait until the XRD is `Established`. The schema has
   these fields:

   | Field | Type | Rules |
   | --- | --- | --- |
   | `spec.team` | string | Required |
   | `spec.size` | string | Only `small`, `medium` or `large`; default `small` |
   | `spec.replicas` | integer | From `1` to `3`; default `1` |
   | `spec.contact` | string | Optional |
   | `status.availableReplicas` | integer | Written by the platform |

   The API server must refuse a request with no `team`, `replicas: 0`, `replicas: 4`,
   `size: huge` or an undeclared field. Fix this in the schema. Do not switch off the
   checking of unknown fields.

5. **Write the Composition.** Create a Composition named `teamenvironment` for the kind
   `TeamEnvironment`, in `mode: Pipeline` with `function-patch-and-transform`. For each
   request, it creates two `Object` resources that use the `ClusterProviderConfig`
   `in-cluster`:
   - A Deployment named `scout`, with the image `ghcr.io/stefanprodan/podinfo:6.15.0`, the
     pod label `app: scout` and container port `9898`.
   - A Service named `scout` that selects `app: scout` and listens on port `9898`.

   Both must be created in the namespace of the request. The Deployment must take its
   replicas from `spec.replicas` of the request, and its pods must carry the label `team`
   with the value of `spec.team`. The Composition must write the available replicas of the
   Deployment back to `status.availableReplicas` of the request.

6. **Request an environment as the tenant.** In the namespace `outpost`, create a
   `TeamEnvironment` named `scout-env` with `team: outpost`, `size: medium` and
   `replicas: 2`. Its `Synced` and `Ready` conditions must both be `True`, and
   `kubectl -n outpost get teamenvironment scout-env` must show `2` in its available
   replicas.

7. **Prove that the workload answers.** A request from the `shuttle` pod to
   `http://scout:9898` must return the HTTP status code `200`.

## Rules

- Do not create, edit or delete the Deployment, the Service or any `Object` resource by
  hand. Crossplane must create them from the Composition.
- Do not give the provider `cluster-admin`, a wildcard rule or a ClusterRoleBinding.
- Do not hard-code the replica count in the Composition. When the request changes to
  `replicas: 3`, the Deployment must change to 3.
- Do not add a second provider configuration.
