# Solution Walkthrough

You work on the `terminal` of the lab cluster. You find the worker for the finalizer, read why it cannot finish, give its ServiceAccount the one missing permission, and start the Job. The finalizer on `probe-settings` stays in place until the worker removes it.

| Goal | Where it lives | Command or field |
| --- | --- | --- |
| Show that deletion was requested | `metadata.deletionTimestamp` and `metadata.finalizers` of the ConfigMap | `kubectl get configmap ... -o jsonpath` |
| Find the worker for the finalizer | the annotation `platform.starfleet.io/cleanup-job` | the Job `probe-cleanup` |
| Check what the worker may do | RBAC for the ServiceAccount | `kubectl auth can-i ... --as=system:serviceaccount:starfleet:probe-cleanup` |
| Start a suspended Job | `spec.suspend` of the Job | `kubectl patch job ... -p '{"spec":{"suspend":false}}'` |

## The feedback loop

Grading runs from the host terminal, the shell where you typed `astrona run`, not inside the cluster:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-02
```

The grader has two checks: `cleanup-complete` and `cleanup-rbac`. At the start, `cleanup-complete` fails because the Job is suspended. `cleanup-rbac` fails because the worker cannot delete `probe-cache`. Run the command after each fix and read both results.

---

## Step 1: Read the deletion fields

Print the fields that decide whether deletion can finish:

```sh
kubectl -n starfleet get configmap probe-settings -o jsonpath='deletionTimestamp={.metadata.deletionTimestamp} finalizers={.metadata.finalizers}{"\n"}'
kubectl -n starfleet get configmap probe-settings -o jsonpath='{.metadata.annotations.platform\.starfleet\.io/cleanup-job}{"\n"}'
```

The deletion timestamp is set, and the finalizer `platform.starfleet.io/cleanup` is still there. The annotation names the worker: `probe-cleanup`. No check turns green in this step.

---

## Step 2: Look at the worker

Read the Job and its pods:

```sh
kubectl -n starfleet get job probe-cleanup -o custom-columns=NAME:.metadata.name,SUSPEND:.spec.suspend,ACTIVE:.status.active
kubectl -n starfleet get pods -l job-name=probe-cleanup
```

The column `SUSPEND` is `true` and there are no pods, so no worker runs. Starting the Job is one fix. Before you do it, check that the worker is allowed to finish. A worker that starts and fails is harder to read than a permission you checked first. No check turns green in this step.

---

## Step 3: Check the permissions of the worker

Ask the API server what the ServiceAccount may do:

```sh
kubectl -n starfleet auth can-i delete configmap/probe-cache --as=system:serviceaccount:starfleet:probe-cleanup
kubectl -n starfleet auth can-i patch configmap/probe-settings --as=system:serviceaccount:starfleet:probe-cleanup
```

The first command prints `no`. The second prints `yes`. The worker can release the finalizer but cannot delete the cache, which is the first step of the contract. Read the Role to see why:

```sh
kubectl -n starfleet get role probe-cleanup -o yaml
```

The rule for `probe-cache` lists `get`, `list` and `watch` but not `delete`. That is the fault. No check turns green in this step.

---

## Step 4: Add the missing verb

Change only the rule for `probe-cache`. Save this as `role-probe-cleanup.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: probe-cleanup
  namespace: starfleet
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    resourceNames: ["probe-settings"]
    verbs: ["get", "list", "watch", "patch"]
  - apiGroups: [""]
    resources: ["configmaps"]
    resourceNames: ["probe-cache"]
    verbs: ["get", "list", "watch", "delete"]
```

- `resourceNames` limits each rule to one ConfigMap by name. Without it, the rule would cover every ConfigMap in `starfleet`, and the grader rejects that.
- The first rule is unchanged: the worker may patch `probe-settings` to remove its finalizer, but not delete it.
- The second rule adds `delete`. The worker needs `get`, `list` and `watch` too, because `kubectl delete --wait=true` and `kubectl wait` watch the object.

Apply it:

```sh
kubectl apply -f role-probe-cleanup.yaml
kubectl -n starfleet auth can-i delete configmap/probe-cache --as=system:serviceaccount:starfleet:probe-cleanup
```

The second command now prints `yes`. Run the check. `cleanup-rbac` now passes.

---

## Step 5: Start the worker

Resume the Job. Do not change anything else in it:

```sh
kubectl -n starfleet patch job probe-cleanup --type=merge -p '{"spec":{"suspend":false}}'
kubectl -n starfleet wait --for=condition=Complete job/probe-cleanup --timeout=180s
```

The Job runs three containers in order. The first waits for the deletion timestamp, the second deletes `probe-cache`, and the third removes the finalizer from `probe-settings`. Read their logs:

```sh
kubectl -n starfleet logs job/probe-cleanup --all-containers=true
```

Then confirm that both ConfigMaps are gone:

```sh
kubectl -n starfleet get configmap probe-settings probe-cache --ignore-not-found -o name
```

The command prints nothing. Run the check. `cleanup-complete` now passes.

---

## Step 6: Submit

When both checks are green, run the submit command once more:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-02
```

---

## If a check stays red

- **`cleanup-complete` fails with "still suspended".** The Job was not resumed. Run the patch from step 5.
- **`cleanup-complete` fails with "not Complete".** Read the logs with `kubectl -n starfleet logs job/probe-cleanup --all-containers=true`. If the second container shows `forbidden`, the Role still lacks `delete` on `probe-cache`. If you started the Job before you fixed the Role, a failed pod is retried with a growing delay, so wait one or two minutes after the fix.
- **`cleanup-complete` fails and the Job never completes after you removed the finalizer yourself.** The first container waits for `probe-settings` to have a deletion timestamp, and the object is already gone, so the worker cannot finish. The cleanup of `probe-cache` was skipped too. Destroy the lab and start again.
- **`cleanup-complete` fails with "probe-cache still exists".** The Job did not finish its second step. Check the Role and the logs of the second container.
- **`cleanup-rbac` fails with "can delete every ConfigMap" or "can do everything".** You removed `resourceNames` or bound `cluster-admin`. Apply the Role from step 4 and delete any extra RoleBinding or ClusterRoleBinding you added.
- **`cleanup-rbac` fails with "can delete probe-settings".** You gave `delete` to the rule for `probe-settings`. The worker may only patch it.
