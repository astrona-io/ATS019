# ProviderConfig And Injected Identity

A running provider knows how to talk to an API, but not which API or with which credentials. Cloud providers need an account and a secret key. `provider-kubernetes` needs the address of a Kubernetes cluster and a user that can change objects in it. The ProviderConfig carries that information, and every managed resource points at one.

A ProviderConfig has a `credentials` block with a `source`. The source says where the provider gets its identity. Two sources matter here:

- `Secret`: the identity is a kubeconfig stored in a Kubernetes Secret. Use this to manage a different cluster.
- `InjectedIdentity`: the provider uses the identity Kubernetes injects into its own pod, which is the pod's ServiceAccount token. Use this to manage the cluster the provider runs in.

With `InjectedIdentity`, no secret is stored anywhere. The provider acts as its own ServiceAccount, so Kubernetes RBAC decides what it may do. That detail is the subject of the rest of this part.

## Create a ProviderConfig in the tenant namespace

In Crossplane 2.x, the namespaced ProviderConfig lives in the same namespace as the managed resources that use it. The `outpost` tenant gets its own. A `ClusterProviderConfig` of the same shape exists for configuration shared by all namespaces.

<!-- astrona:playground:renew -->

Save this as `providerconfig-in-cluster.yaml`:

```yaml
apiVersion: kubernetes.m.crossplane.io/v1alpha1
kind: ProviderConfig
metadata:
  name: in-cluster
  namespace: outpost
spec:
  credentials:
    source: InjectedIdentity
```

Apply it:

```sh
kubectl apply -f providerconfig-in-cluster.yaml
```

You should see `providerconfig.kubernetes.m.crossplane.io/in-cluster created`. Then check the result:

```sh
kubectl -n outpost get providerconfigs.kubernetes.m.crossplane.io
```

You should see one row named `in-cluster`. The object has no `Ready` condition to wait for. Creating it only records settings; the provider reads it when a managed resource refers to it.

## Ask what the provider may do

The ProviderConfig said "use the injected identity". It did not say what that identity may do. Kubernetes answers that question. The provider pod runs as the ServiceAccount `provider-kubernetes` in `crossplane-system`, the name you set with the `DeploymentRuntimeConfig`. Ask the API server whether it may create a Service in `outpost`:

```sh
kubectl auth can-i create services -n outpost \
  --as=system:serviceaccount:crossplane-system:provider-kubernetes
```

You should see `no`. Crossplane's RBAC manager gives a provider access to its own CRDs and to a few core kinds it needs for itself, such as ConfigMaps, Secrets, Events and Leases. It does not give the provider access to Services, Deployments or the other objects it will manage, because only you know which objects those are. This is deliberate: a provider that managed every object in the cluster would hold too much power.

You can now configure how a provider connects, and you know that `InjectedIdentity` puts the permission question in the hands of Kubernetes RBAC. The ProviderConfig is valid, but the provider cannot yet create a single Service. The next part creates a managed resource, watches it fail for exactly that reason, and fixes it.

## Common pitfalls

> [!WARNING]
> - **Creating the ProviderConfig in the wrong namespace.** A namespaced managed resource finds its ProviderConfig in its own namespace.
> - **Expecting the ProviderConfig to grant permissions.** It names an identity; it never changes RBAC.
> - **Using `Secret` for the same cluster.** `InjectedIdentity` avoids storing a kubeconfig that you must rotate.
> - **Granting `cluster-admin` to make errors go away.** Grant only the verbs and resources the provider needs in the namespace it serves.
