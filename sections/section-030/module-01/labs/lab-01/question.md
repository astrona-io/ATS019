# Question

Solve this question on: `terminal`

The platform team runs Crossplane 2.4.2 in the namespace `crossplane-system`. No provider is installed yet. The `outpost` team will soon ask the platform to create Kubernetes objects through Crossplane, so the platform team installs `provider-kubernetes`. Later steps grant this provider permissions, so its pod must run under a ServiceAccount with a name that does not change.

Install the provider and make it healthy. When you finish, these must be true:

- A `DeploymentRuntimeConfig` (the `pkg.crossplane.io/v1beta1` object that sets options for a provider's Deployment) exists. It sets the name of the provider's ServiceAccount to `provider-kubernetes`.
- A `Provider` named `provider-kubernetes` exists. Its package is `xpkg.crossplane.io/crossplane-contrib/provider-kubernetes:v1.4.1`, and its `runtimeConfigRef` names your `DeploymentRuntimeConfig`.
- `kubectl get providers` shows `True` under both `INSTALLED` and `HEALTHY` for `provider-kubernetes`.
- The provider pod in `crossplane-system` is running, and its ServiceAccount is `provider-kubernetes`.
- The CRD `objects.kubernetes.m.crossplane.io` exists in the cluster.

Pin the version tag in the package. Do not change the provider's Deployment or pod by hand: Crossplane owns them and puts the configuration back.
