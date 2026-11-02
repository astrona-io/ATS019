# Scope A Tenant With A Role And RoleBinding

A platform API does not make a platform self-service by itself. If a tenant can reach the cluster only through an administrator, every request waits for a person. If the tenant has too many rights, one mistake reaches every team. This part gives the tenant exactly one right: to request and read `TeamEnvironment` objects in its own namespace.

## Start from what the tenant cannot do

Role-Based Access Control (RBAC) is the Kubernetes authorization system. A Role is a namespaced list of rules. Each rule names API groups, resources and verbs. A RoleBinding grants the rules of a Role to users, groups or ServiceAccounts in the same namespace.

The command `kubectl auth can-i` asks the API server whether an identity may do an action. The flag `--as` sends the request as another user, and `--as-group` adds a group to that identity. Your own administrator account may impersonate, so you can test the tenant without logging in as it.

<!-- astrona:playground:renew -->

Ask whether the tenant can create a `TeamEnvironment` before any RBAC exists:

```sh
kubectl auth can-i create teamenvironments.platform.starfleet.io -n outpost --as outpost-dev --as-group outpost-team
```

You should see `no`. The user has no Role, so the API server denies everything. The name `teamenvironments.platform.starfleet.io` is the plural resource name followed by the API group, which is the form RBAC rules use.

## Write the Role

A rule lists the resource, not the verb alone, so the Role is the place where "only this kind" is decided. Save this as `role-teamenvironment-requester.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: teamenvironment-requester
  namespace: outpost
rules:
  - apiGroups: ["platform.starfleet.io"]
    resources: ["teamenvironments"]
    verbs: ["create", "get", "list", "watch"]
```

The verbs `get`, `list` and `watch` let the tenant read its requests and wait for them. The verb `create` lets it file one. The Role has no `update` or `delete`, so the tenant cannot change or remove a request after the platform accepts it. Add those verbs only when the platform wants tenants to do that.

Apply it:

```sh
kubectl apply -f role-teamenvironment-requester.yaml
```

A Role grants nothing until a RoleBinding names who receives it. Save this as `rolebinding-outpost-team.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: outpost-team-teamenvironment-requester
  namespace: outpost
subjects:
  - kind: Group
    name: outpost-team
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: teamenvironment-requester
  apiGroup: rbac.authorization.k8s.io
```

The subject is the group `outpost-team`, not the user. Every member of the group receives the rights, so a new team member needs no new binding. The `roleRef` of a RoleBinding cannot change after creation. To point a binding at another Role, delete it and create it again.

Apply it:

```sh
kubectl apply -f rolebinding-outpost-team.yaml
```

## Prove the limits

A test that only shows "yes" proves little. Check the allowed action and the actions that must stay denied:

```sh
kubectl auth can-i create teamenvironments.platform.starfleet.io -n outpost --as outpost-dev --as-group outpost-team
kubectl auth can-i create deployments.apps -n outpost --as outpost-dev --as-group outpost-team
kubectl auth can-i get secrets -n outpost --as outpost-dev --as-group outpost-team
kubectl auth can-i create teamenvironments.platform.starfleet.io -n starfleet --as outpost-dev --as-group outpost-team
```

You should see `yes`, then `no`, `no` and `no`. The Deployment is denied because the Role names only one resource. The Secret is denied for the same reason. The last line is denied because a RoleBinding works only in its own namespace, so the rights end at the edge of `outpost`.

The tenant never touches the Deployment or Service. Crossplane creates them with its own identity. This is the central idea of self-service on a platform: the tenant holds the right to ask, and the platform controller holds the right to build.

The tenant can create a request now, but the request must reach the cluster in some way. The next part makes the same rights follow the platform's own built-in roles, and then the module moves the request into Git.

## Common pitfalls

> [!WARNING]
> - **Binding `cluster-admin` "to make it work".** The tenant can then read every Secret in the cluster. Write the narrow Role instead.
> - **Testing without `--as-group`.** The RoleBinding names a group. With only `--as outpost-dev` the identity has no group, so the check returns `no` even when the Role is right.
> - **Writing the resource as `teamenvironment`.** RBAC rules use the plural resource name. A singular name matches nothing and the check returns `no`.
> - **Checking only the allowed action.** Also check a denied action and a second namespace, or a rule that is too wide goes unnoticed.
