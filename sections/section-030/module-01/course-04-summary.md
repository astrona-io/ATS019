# Summary

Crossplane core manages packages. A provider is a package that adds CRDs and a controller for one external system. The `Provider` object names the package, and `kubectl get providers` reports two facts: `INSTALLED` means the package manager unpacked it, and `HEALTHY` means its pod runs. Neither fact proves the provider can reach anything.

A ProviderConfig tells a provider how to connect. With the `InjectedIdentity` source, the provider uses its own pod's ServiceAccount, so Kubernetes RBAC decides what it may do. The ProviderConfig names an identity and never grants permissions. In Crossplane 2.x, the namespaced ProviderConfig sits in the same namespace as the managed resources that use it.

A managed resource is one object a provider reconciles. `Synced` says whether the provider could reconcile it, and `Ready` says whether the external resource exists. A failed sync puts the cause in the `Synced` condition message and in the events. A `forbidden` error from the API server means the provider's ServiceAccount lacks a verb. The fix is a Role and RoleBinding in the right namespace, not a change to the managed resource. Deleting the managed resource also deletes what it created.

Key facts:

- The package manager is the `crossplane` pod. The `crossplane-rbac-manager` pod gives a provider access to its own CRDs only.
- `provider-kubernetes` wraps any Kubernetes manifest in an `Object`. Everything in this module runs inside one cluster, so it needs no cloud account.
- Fix a fixed ServiceAccount name with a `DeploymentRuntimeConfig` so RBAC can refer to it.
- Grant the least access that works: the verbs and resources needed, in the namespace served.

<!-- astrona:playground:destroy -->
