# Question

Solve this question on: `terminal`

The `outpost` team asked the platform team for a Service named `scout` in the namespace `outpost`. The platform team creates it through Crossplane: the `Object` named `scout` in `outpost` wraps the Service, and `provider-kubernetes` creates it. The `Object` has been stuck for hours and the Service does not exist.

`provider-kubernetes` is installed and healthy. It runs as the ServiceAccount `provider-kubernetes` in `crossplane-system`, and the ProviderConfig `in-cluster` in `outpost` uses its injected identity. Find out why the `Object` does not sync and repair it. Do not change the `Object` or the ProviderConfig.

When you finish, these must be true:

- The `Object` `scout` in `outpost` (`objects.kubernetes.m.crossplane.io`) has the conditions `Synced` and `Ready`, both with status `True`.
- The Service `scout` exists in `outpost` with the selector `app: scout` and the port `9898`.
- The ServiceAccount `provider-kubernetes` in `crossplane-system` may `get`, `create`, `update` and `delete` Services in `outpost`.
- That is all it may do for Services. It must not gain access to Services in other namespaces, to Services in all namespaces at once, or to other kinds such as Deployments. It must not become `cluster-admin`.

Do not create the Service yourself: the provider must create it.
