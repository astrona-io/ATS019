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

For tenants, keep the narrow Role. Use aggregation for the platform's own users, so they get the new kind with no extra binding. The rule of thumb for the exam is this: choose a Role and RoleBinding to limit a team, choose the aggregation label to extend a built-in role.

You can now give a tenant a narrow set of rights and extend the built-in roles when the platform adds a kind. The permissions are ready, but the request still has to arrive by a safe path. The next part sends it through Git.

## Common pitfalls

> [!WARNING]
> - **Editing the built-in `edit` ClusterRole.** The control plane overwrites changes to an aggregated role. Add a labelled ClusterRole instead.
> - **A wrong label value.** The label value must be the string `"true"`. Without quotes, YAML reads a boolean, and Kubernetes rejects it as a label value.
> - **Binding tenants to `edit` or `view` for convenience.** `edit` reads Secrets, and `view` reads most namespaced objects. Tenant rights should list only the platform API.

## Your mission: Scope A Tenant To One Platform API With RBAC

You can now write a Role, a RoleBinding and an aggregated ClusterRole, and prove their limits with `kubectl auth can-i`. The mission asks you to give the group `outpost-team` the right to create and read `TeamEnvironment` objects in `outpost`, and to prove that it cannot create Deployments or read Secrets.

Pause the playground first:

```sh
astrona stop ats-019-playground-040-03
```

Start the lab and send your work for grading:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-03/labs/lab-01
astrona submit -c sections/section-040/module-03/labs/lab-01
```

When the lab is done, remove it and start the playground again:

```sh
astrona destroy ats-019-lab-040-03
astrona start ats-019-playground-040-03
```
