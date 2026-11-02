# Solution Walkthrough

You work on the `terminal` of the lab cluster. You read the `Synced` condition of the stuck `Object`, find the missing permission, and change one Role. The `Object`, the ProviderConfig and the provider stay untouched.

| Goal | Where it lives | Command or object |
| --- | --- | --- |
| Find out why a managed resource fails | `status.conditions` of the `Object` | the message of the `Synced` condition |
| See what the provider may do | the Kubernetes API server | `kubectl auth can-i ... --as=system:serviceaccount:crossplane-system:provider-kubernetes` |
| Change what the provider may do | RBAC in the namespace of the managed object | the Role `provider-kubernetes-services` in `outpost` |
| Prove the repair | status of the `Object` | `Synced` and `Ready` both `True` |

## The feedback loop

Grading runs from the host terminal, the shell where you typed `astrona run`, not inside the cluster:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-02
```

The grader has two checks: `object-synced` and `provider-rbac`. At the start, `object-synced` fails because the `Object` is not `Synced`. `provider-rbac` fails because the provider cannot create Services. Run the command after the repair and read both results.

---

## Step 1: Read the conditions of the Object

List the `Object` and print its conditions:

```sh
kubectl -n outpost get objects.kubernetes.m.crossplane.io
kubectl -n outpost get objects.kubernetes.m.crossplane.io scout \
  -o jsonpath='{range .status.conditions[*]}{.type}{" "}{.status}{" reason="}{.reason}{"\n"}{end}'
```

The `Synced` condition has status `False`. The `Ready` condition is not `True`. No check turns green in this step.

---

## Step 2: Read the message

The `reason` and `message` of the `Synced` condition say why the provider failed:

```sh
kubectl -n outpost get objects.kubernetes.m.crossplane.io scout \
  -o jsonpath='{.status.conditions[?(@.type=="Synced")].message}{"\n"}'
```

The message contains the word `forbidden`. It names the ServiceAccount `system:serviceaccount:crossplane-system:provider-kubernetes`, the verb `patch`, the resource `services` and the namespace `outpost`. The error comes from the Kubernetes API server, so the fault is in RBAC, not in the `Object`.

---

## Step 3: Check what the provider may do

Ask the API server about the verbs the provider needs:

```sh
kubectl auth can-i get services -n outpost --as=system:serviceaccount:crossplane-system:provider-kubernetes
kubectl auth can-i create services -n outpost --as=system:serviceaccount:crossplane-system:provider-kubernetes
```

The first command prints `yes`. The second prints `no`. The provider can read Services but cannot create them. No check turns green in this step.

---

## Step 4: Read the Role

The Role `provider-kubernetes-services` and its RoleBinding already exist in `outpost`:

```sh
kubectl -n outpost get role provider-kubernetes-services -o yaml
kubectl -n outpost get rolebinding provider-kubernetes-services -o yaml
```

The RoleBinding gives the Role to the ServiceAccount `provider-kubernetes` in `crossplane-system`, which is correct. The Role lists only the verbs `get`, `list` and `watch`. That is the fault.

---

## Step 5: Add the missing verbs

Edit the Role, not the `Object`. Save this as `role-provider-kubernetes-services.yaml`:

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

- `kind: Role` limits the permission to the namespace in `metadata.namespace`. A ClusterRole bound with a ClusterRoleBinding would give access in every namespace, and the grader rejects that.
- `resources: ["services"]` limits the rule to Services.
- `verbs` adds `create`, `update`, `patch` and `delete` to the read verbs.

Apply it:

```sh
kubectl apply -f role-provider-kubernetes-services.yaml
```

Check the permission again:

```sh
kubectl auth can-i create services -n outpost --as=system:serviceaccount:crossplane-system:provider-kubernetes
```

The command prints `yes`. Run the check. `provider-rbac` now passes.

---

## Step 6: Wait for the provider to retry

The provider retries a failed reconcile with a growing delay, so the `Object` can take up to a few minutes to recover. Wait for it:

```sh
kubectl -n outpost wait objects.kubernetes.m.crossplane.io/scout --for=condition=Ready --timeout=300s
kubectl -n outpost get service scout \
  -o jsonpath='{.spec.selector}{" "}{.spec.ports[0].port}{"\n"}'
```

The `Object` becomes `Ready`, and the Service has the selector `app: scout` and the port `9898`. Run the check. `object-synced` now passes.

---

## Step 7: Submit

When both checks are green, run the submit command once more:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-02
```

---

## If a check stays red

- **`object-synced` fails with "the Object is not Synced".** The provider has not retried yet, or the Role is still too small. Run `kubectl auth can-i create services -n outpost --as=system:serviceaccount:crossplane-system:provider-kubernetes`. If it prints `yes`, wait one or two minutes and run the check again.
- **`provider-rbac` fails with "cannot create services in outpost".** The Role is not changed, or you changed a Role in another namespace. The Role must be in `outpost`, not in `crossplane-system`.
- **`provider-rbac` fails with "can list Services in all namespaces" or "can do everything".** You used a ClusterRoleBinding or `cluster-admin`. Remove that binding and keep the namespaced Role.
- **`object-synced` fails with "was changed".** You edited the `Object` or the ProviderConfig. The manifest was correct. Restore the original values: the Service selector `app: scout`, the Service port `9898` and `providerConfigRef` `in-cluster`.
- **The Service exists but a check fails.** If you created the Service by hand, delete it and let the provider create it. The provider needs the `update` and `delete` verbs to manage it.
