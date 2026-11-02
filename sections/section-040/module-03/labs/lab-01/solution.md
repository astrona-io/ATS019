# Solution Walkthrough

You will create one Role and one RoleBinding in the namespace `outpost`, then prove the limits with `kubectl auth can-i`. You change nothing outside `outpost`, and you do not touch the `TeamEnvironment` API itself.

| Goal | Where it lives | Object or command |
| --- | --- | --- |
| Which verbs on which resource | Namespace `outpost` | A Role with one rule |
| Who receives the rights | Namespace `outpost` | A RoleBinding with the group as subject |
| Proof | Any terminal | `kubectl auth can-i ... --as outpost-dev --as-group outpost-team` |

## The feedback loop

Grading runs from the host terminal, the shell where you typed `astrona run`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-03/labs/lab-01
```

The grader prints `PASS` or `FAIL` for each check. Run it now and every
check about the allowed actions fails, because the group has no rights. Run it
again after each step.

---

## Step 1: Look at the starting state

Ask the API server what the tenant may do:

```sh
kubectl auth can-i create teamenvironments.platform.starfleet.io -n outpost --as outpost-dev --as-group outpost-team
kubectl get roles,rolebindings -n outpost
```

The first command prints `no`. The second finds no Role or RoleBinding.
No check turns green in this step.

---

## Step 2: Create the Role

Save this as `role-teamenvironment-requester.yaml`:

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

The `apiGroups` field is the API group of the resource. The `resources` field uses the plural name, `teamenvironments`. The `verbs` field lists the four verbs from the task and nothing else.

Apply it:

```sh
kubectl apply -f role-teamenvironment-requester.yaml
```

A Role grants nothing until a RoleBinding names who receives it, so no check turns green yet.

---

## Step 3: Bind the group

Save this as `rolebinding-outpost-team.yaml`:

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

The `subjects` list names the group `outpost-team`. The `roleRef` points to the Role from step 2. Apply it:

```sh
kubectl apply -f rolebinding-outpost-team.yaml
```

Run `astrona submit` now. The checks for the allowed actions, the four verbs, the other resources, the other namespaces and the group all pass.

---

## Step 4: Prove the limits

```sh
kubectl auth can-i create teamenvironments.platform.starfleet.io -n outpost --as outpost-dev --as-group outpost-team
kubectl auth can-i create deployments.apps -n outpost --as outpost-dev --as-group outpost-team
kubectl auth can-i get secrets -n outpost --as outpost-dev --as-group outpost-team
kubectl auth can-i create teamenvironments.platform.starfleet.io -n starfleet --as outpost-dev --as-group outpost-team
```

The answers are `yes`, `no`, `no` and `no`.

---

## Step 5: Submit

When every check shows `PASS`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-03/labs/lab-01
```

---

## If a check stays red

- **The allowed-action check fails.** The Role has the wrong `apiGroups` or a singular resource name. Use `platform.starfleet.io` and `teamenvironments`.
- **The group check fails and says the binding names the user.** The subject has `kind: User`. Change it to `kind: Group` and the name `outpost-team`.
- **The verb check fails.** The Role lists `update`, `patch`, `delete` or `"*"`. List only `create`, `get`, `list` and `watch`.
- **The resource check fails.** You bound a built-in ClusterRole such as `edit`, or the Role names `"*"` as the resource. Delete that binding and keep the narrow Role.
- **The namespace check fails.** You created a ClusterRoleBinding. Delete it and use the RoleBinding in `outpost`.
- **`can-i` prints `no` for the allowed action.** You left out `--as-group outpost-team`. The binding names the group, so the check needs the group.
