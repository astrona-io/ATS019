# Managed Resources And Failed Syncs

A managed resource is the smallest unit a provider reconciles. In `provider-kubernetes`, the managed resource is an `Object`. It wraps any Kubernetes manifest. The provider creates that manifest in the target cluster, watches it, and repairs drift. The `Object` reports its progress in two conditions, and reading them is the main debugging skill for Crossplane.

The conditions mean different things. `Synced` says whether the provider could reconcile the managed resource: read the desired state, talk to the external system, and apply the change. `Ready` says whether the external resource exists and is usable. A resource that cannot be reconciled has `Synced False`, and the message says why.

## Create an Object

The `Object` below asks the provider to create a Service named `scout` in `outpost`. The `forProvider.manifest` field holds the Service. The `providerConfigRef` field names the ProviderConfig from the previous part.

<!-- astrona:playground:renew -->

Save this as `object-scout-service.yaml`:

```yaml
apiVersion: kubernetes.m.crossplane.io/v1alpha1
kind: Object
metadata:
  name: scout
  namespace: outpost
spec:
  forProvider:
    manifest:
      apiVersion: v1
      kind: Service
      metadata:
        namespace: outpost
      spec:
        selector:
          app: scout
        ports:
          - port: 9898
            targetPort: 9898
  providerConfigRef:
    kind: ProviderConfig
    name: in-cluster
```

Apply it:

```sh
kubectl apply -f object-scout-service.yaml
```

You should see `object.kubernetes.m.crossplane.io/scout created`. The manifest has no `metadata.name`, so the provider uses the name of the `Object`. Now read the conditions:

```sh
kubectl -n outpost get objects.kubernetes.m.crossplane.io scout \
  -o jsonpath='{range .status.conditions[*]}{.type}{" "}{.status}{" reason="}{.reason}{"\n"}{end}'
```

You should see a `Synced` line with status `False`. The `Ready` condition is not `True`. The Service does not exist:

```sh
kubectl -n outpost get service scout
```

You should see `Error from server (NotFound)`.

## Read why the sync failed

The `Synced` condition carries a `reason` and a `message`. Print the message of that condition:

```sh
kubectl -n outpost get objects.kubernetes.m.crossplane.io scout \
  -o jsonpath='{.status.conditions[?(@.type=="Synced")].message}{"\n"}'
```

You should see a message that ends with an error from the Kubernetes API server saying that the ServiceAccount `system:serviceaccount:crossplane-system:provider-kubernetes` cannot patch resource `services` in the namespace `outpost`, with the word `forbidden`. The same text appears under `Events` in `kubectl -n outpost describe objects.kubernetes.m.crossplane.io scout`.

Three facts in that message locate the fault. The error comes from the API server, not from Crossplane. The identity is the provider's ServiceAccount, so the ProviderConfig worked. The missing permission is on `services` in `outpost`. The fix belongs in RBAC, not in the `Object`.

## Grant the missing permission

A Role lists verbs on resources in one namespace. A RoleBinding gives a Role to a subject. The provider must read, create, update and delete Services in `outpost`. Save this as `role-provider-kubernetes-services.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: provider-kubernetes-services
  namespace: outpost
rules:
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

Save this as `rolebinding-provider-kubernetes-services.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: provider-kubernetes-services
  namespace: outpost
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: provider-kubernetes-services
subjects:
  - kind: ServiceAccount
    name: provider-kubernetes
    namespace: crossplane-system
```

Apply both files:

```sh
kubectl apply -f role-provider-kubernetes-services.yaml
kubectl apply -f rolebinding-provider-kubernetes-services.yaml
```

The provider retries a failed reconcile with a growing delay, so the `Object` can take up to a minute or two to recover. Wait for it and then check the Service:

```sh
kubectl -n outpost wait objects.kubernetes.m.crossplane.io/scout --for=condition=Ready --timeout=300s
kubectl -n outpost get service scout \
  -o jsonpath='{.spec.selector}{" "}{.spec.ports[0].port}{"\n"}'
```

You should see the `Object` become `Ready`, and the selector and port of the Service. Read the conditions again and both `Synced` and `Ready` are `True`. The provider's ServiceAccount did the work, and the `Object` did not change at all.

## Delete through the Object

Crossplane keeps the lifecycle of the wrapped object tied to the `Object`. Delete the `Object` and check the Service:

```sh
kubectl -n outpost delete objects.kubernetes.m.crossplane.io scout
kubectl -n outpost get service scout --ignore-not-found
```

The second command prints nothing, because the default deletion policy of a managed resource is `Delete`. The provider removed the Service before the `Object` disappeared. Deleting the `Object` is therefore the correct way to remove what it created.

You can now create a managed resource, read `Synced` and `Ready`, and trace a failed sync from the condition message to a missing Role. The question left open is how to create many related managed resources from one request. A composition does that, and a platform API sits on top of it.

## Common pitfalls

> [!WARNING]
> - **Editing the `Object` to fix a `forbidden` error.** The manifest is fine; grant the provider's ServiceAccount the missing verb in RBAC.
> - **Granting access in the wrong namespace.** The Role goes in the namespace of the object the provider manages, not in `crossplane-system`.
> - **Reading only `Ready`.** `Synced` holds the reason and message of a failure.
> - **Deleting the Service by hand.** The provider recreates it; delete the `Object` instead.
