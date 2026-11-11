# Aggregate Platform API Permissions Into edit And view

A Role in one namespace solves one tenant. A platform has many namespaces and many people who already hold the built-in roles `edit` and `view`. When the platform adds a new kind, those roles know nothing about it. This part makes the new kind part of them without changing them by hand.

## How aggregation works

A ClusterRole is a cluster-wide list of rules. An aggregated ClusterRole has an `aggregationRule` with label selectors. A controller in the control plane finds every ClusterRole whose labels match and copies their rules into the aggregated one. The built-in `edit` ClusterRole selects the label `rbac.authorization.k8s.io/aggregate-to-edit: "true"`. The built-in `view` ClusterRole selects `rbac.authorization.k8s.io/aggregate-to-view: "true"`.

So the platform team does not edit `edit`. It creates a small ClusterRole with the label, and the control plane adds its rules to `edit`. Save this as `clusterrole-teamenvironment-edit.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: teamenvironment-edit
  labels:
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
rules:
  - apiGroups: ["platform.starfleet.io"]
    resources: ["teamenvironments"]
    verbs: ["create", "get", "list", "watch", "update", "patch", "delete"]
```

<!-- astrona:playground:renew -->

Apply it:

```sh
kubectl apply -f clusterrole-teamenvironment-edit.yaml
```

Read access gets its own ClusterRole, so a holder of `view` can see requests but not change them. Save this as `clusterrole-teamenvironment-view.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: teamenvironment-view
  labels:
    rbac.authorization.k8s.io/aggregate-to-view: "true"
rules:
  - apiGroups: ["platform.starfleet.io"]
    resources: ["teamenvironments"]
    verbs: ["get", "list", "watch"]
```

Apply it:

```sh
kubectl apply -f clusterrole-teamenvironment-view.yaml
```

Then check that the rules reached the built-in roles:

```sh
kubectl get clusterrole edit -o jsonpath='{.rules[?(@.apiGroups[0]=="platform.starfleet.io")].resources}{"\n"}'
```

You should see the resource `teamenvironments` in the output. If the line is empty, wait a few seconds and run it again. The aggregation controller works asynchronously.

## Do not hand out edit to tenants

The aggregated `edit` role is useful for people who run a namespace, but it is wide. The built-in `edit` role can read Secrets and create Deployments. A tenant bound to `edit` would pass the check that allows creating a `TeamEnvironment`, but it would also pass the checks that must be denied, such as creating Deployments and reading Secrets.

For tenants, keep the narrow Role. Use aggregation for the platform's own users, so they get the new kind with no extra binding. For these two access models, choose a Role and RoleBinding to limit a team, choose the aggregation label to extend a built-in role.

You can now give a tenant a narrow set of rights and extend the built-in roles when the platform adds a kind. The permissions are ready, but the request still has to arrive by a safe path. The next part sends it through Git.

## Common pitfalls

> [!WARNING]
> - **Editing the built-in `edit` ClusterRole.** The control plane overwrites changes to an aggregated role. Add a labelled ClusterRole instead.
> - **A wrong label value.** The label value must be the string `"true"`. Without quotes, YAML reads a boolean, and Kubernetes rejects it as a label value.
> - **Binding tenants to `edit` or `view` for convenience.** `edit` reads Secrets, and `view` reads most namespaced objects. Tenant rights should list only the platform API.

## Verify the permission boundary

The independent aggregation lab supplies an editor and a reader bound in `outpost`. After applying the roles, use `kubectl auth can-i` with `--as=platform-editor` or `--as=platform-reader`. Check `create` and `list` on `teamenvironments.platform.starfleet.io` in `outpost`, then repeat in `starfleet`. Only the editor can create; both can list in `outpost`; neither receives these permissions in `starfleet`. The reader must still be unable to read Secrets or create RoleBindings. A successful allowed request alone does not prove that a role is narrow enough.
