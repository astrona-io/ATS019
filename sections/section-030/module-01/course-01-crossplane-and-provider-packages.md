# Crossplane And Provider Packages

A platform API is only useful if something does the work behind it. In Crossplane, that work belongs to providers. Before you install one, you check that Crossplane itself is healthy, because a provider is a package that Crossplane downloads, unpacks and runs. If the package manager is broken, every later step fails with unclear errors.

Crossplane runs as two Deployments in `crossplane-system`. The `crossplane` pod contains the core controllers, including the package manager that installs providers. The `crossplane-rbac-manager` pod creates the RBAC that lets each provider reach its own CRDs. Check both:

<!-- astrona:playground:renew -->

```sh
kubectl -n crossplane-system get deployments
kubectl get crd providers.pkg.crossplane.io providerrevisions.pkg.crossplane.io
```

You should see both Deployments with `READY 1/1`, and both CRDs listed. The `pkg.crossplane.io` group is the package manager's API. A `Provider` object asks for a package. The package manager creates a `ProviderRevision` for each version it installs.

## Install provider-kubernetes

The provider's controller runs as a pod under its own ServiceAccount. Crossplane generates that ServiceAccount name with a random suffix unless you set it. A later step grants permissions to that ServiceAccount, so a fixed name is easier to work with. A `DeploymentRuntimeConfig` sets options for the provider's Deployment, including the ServiceAccount name.

Save this as `deploymentruntimeconfig-provider-kubernetes.yaml`:

```yaml
apiVersion: pkg.crossplane.io/v1beta1
kind: DeploymentRuntimeConfig
metadata:
  name: provider-kubernetes
spec:
  serviceAccountTemplate:
    metadata:
      name: provider-kubernetes
```

Then save this as `provider-kubernetes.yaml`. The `package` field is the full image reference: registry, organisation, name and version tag.

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-kubernetes
spec:
  package: xpkg.crossplane.io/crossplane-contrib/provider-kubernetes:v1.4.1
  runtimeConfigRef:
    name: provider-kubernetes
```

Apply both files:

```sh
kubectl apply -f deploymentruntimeconfig-provider-kubernetes.yaml
kubectl apply -f provider-kubernetes.yaml
```

You should see `created` for both objects. The package manager now pulls the package from `xpkg.crossplane.io`. This takes from a few seconds to a few minutes. Wait for the provider to report healthy, then read its status:

```sh
kubectl wait provider.pkg.crossplane.io/provider-kubernetes --for=condition=Healthy --timeout=300s
kubectl get providers
```

The table has the columns `NAME`, `INSTALLED`, `HEALTHY`, `PACKAGE` and `AGE`. You should see `True` under `INSTALLED` and `HEALTHY`.

These two columns answer different questions. `INSTALLED True` means the package manager downloaded the package and created its CRDs. `HEALTHY True` means the provider's pod is running and ready. A provider can be installed but not healthy, for example when its pod cannot start. Neither column says the provider can connect to anything yet.

## See what the package added

The package manager installed the provider's CRDs in the cluster. List them:

```sh
kubectl get crds -o name | grep kubernetes.m.crossplane.io
kubectl -n crossplane-system get pods
```

You should see CRDs that include `objects.kubernetes.m.crossplane.io`, `providerconfigs.kubernetes.m.crossplane.io` and `clusterproviderconfigs.kubernetes.m.crossplane.io`. You should also see a `provider-kubernetes-...` pod in `Running` state.

The `.m.` in the group name marks the namespaced API of Crossplane 2.x: its managed resources and ProviderConfig live in a namespace. The provider also ships older cluster-scoped kinds in the `kubernetes.crossplane.io` group. This module uses the namespaced kinds.

You now know how a provider arrives: a `Provider` object names a package, the package manager installs it, and `kubectl get providers` shows whether it runs. The provider is healthy but still has no idea which cluster to manage or how to sign in. The next part answers that with a ProviderConfig.

## Common pitfalls

> [!WARNING]
> - **Reading `INSTALLED True` as ready to use.** Check `HEALTHY` as well, and remember that neither column checks credentials.
> - **Installing a provider before Crossplane is ready.** Check the Deployments and the `pkg.crossplane.io` CRDs first.
> - **Leaving the version tag off `spec.package`.** Pin the tag so every cluster runs the same provider version.
> - **Forgetting outbound internet.** The package manager pulls from `xpkg.crossplane.io`; a blocked connection leaves `INSTALLED` unset.
