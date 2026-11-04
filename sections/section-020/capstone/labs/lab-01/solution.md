# Solution Walkthrough

You work on the `terminal` of the lab cluster. You repair three faults in the namespace `outpost`: a `Prometheus` resource that does not reconcile, ConfigMaps without an owner reference, and a ConfigMap stuck in Terminating. The operator, the `TeamEnvironment` and the ConfigMap `shared-notes` stay as they are.

| Goal | Where it lives | Command or object |
| --- | --- | --- |
| Find why a reconcile failed | `status.conditions` of the custom resource, the log of the operator, the events of the owned StatefulSet | `kubectl get prometheus`, `kubectl logs`, `kubectl get events` |
| Make the garbage collector delete a dependent | `metadata.ownerReferences` of the dependent | the owner's kind, name and real UID |
| Find why an object stays in Terminating | `metadata.deletionTimestamp` and `metadata.finalizers` | the component that implements the finalizer |
| Let a worker clean up with minimal access | Role and RoleBinding in the namespace | `kubectl auth can-i ... --as=system:serviceaccount:outpost:scout-cleanup` |

## The feedback loop

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch -c sections/section-020/capstone/labs/lab-01
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

The grader has five checks: `prometheus-reconciled`, `prometheus-identity`, `ownership`, `cleanup-done` and `cleanup-access`. At the start all five fail. The watch terminal shows each check as it turns green.

---

## Step 1: Read the conditions of the Prometheus resource

Print the conditions with their reason and message:

```sh
kubectl -n outpost get prometheus outpost-metrics \
  -o jsonpath='{range .status.conditions[*]}{.type}{" "}{.status}{" reason="}{.reason}{" message="}{.message}{"\n"}{end}'
```

The `Reconciled` condition is `False`. Its message says the operator could not load the additional scrape configuration because the Secret `extra-scrape` does not exist. The operator log has the same error. Search it for the key of the object:

```sh
kubectl -n default logs deploy/prometheus-operator --since=5m | grep outpost/outpost-metrics | tail -3
```

No check turns green in this step.

---

## Step 2: Create the Secret the operator reads

The resource must keep `additionalScrapeConfigs`, so create the Secret instead of removing the reference. An empty list is a valid set of scrape jobs. Save this as `secret-extra-scrape.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: extra-scrape
  namespace: outpost
stringData:
  jobs.yaml: "[]"
```

Apply it:

```sh
kubectl apply -f secret-extra-scrape.yaml
```

The operator watches Secrets, so it reconciles again. Read the conditions again. `Reconciled` becomes `True` and `Available` stays `False` with the reason `NoPodReady`. The operator did its work. The cause of the missing pod is further down.

---

## Step 3: Read the events of the owned StatefulSet

The operator owns the StatefulSet `prometheus-outpost-metrics`, and the built-in StatefulSet controller creates its pods:

```sh
kubectl -n outpost get events --field-selector involvedObject.name=prometheus-outpost-metrics \
  -o custom-columns=TYPE:.type,REASON:.reason,MESSAGE:.message
```

The `FailedCreate` event says the pod cannot be created because the ServiceAccount `prometheus-reader` is not found. List the ServiceAccounts in `outpost`:

```sh
kubectl -n outpost get serviceaccounts
kubectl auth can-i list pods -n outpost --as=system:serviceaccount:outpost:prometheus
```

The ServiceAccount `prometheus` exists and the second command prints `yes`: the platform team bound it to a ClusterRole that reads pods, endpoints, services and EndpointSlices.

---

## Step 4: Point the resource at the real ServiceAccount

Change the custom resource, not the StatefulSet. The operator copies the value into the StatefulSet:

```sh
kubectl -n outpost patch prometheus outpost-metrics --type merge -p '{"spec":{"serviceAccountName":"prometheus"}}'
kubectl -n outpost wait --for=condition=Available --timeout=180s prometheus/outpost-metrics
```

Check the watch terminal. `prometheus-reconciled` and `prometheus-identity` now pass.

A new ServiceAccount named `prometheus-reader` would start the pod, but it would have no access to targets, and `prometheus-identity` would still fail.

---

## Step 5: Read the owner of the environment

Print the UID of the `TeamEnvironment`. The UID identifies this exact object. A recreated object with the same name has a different UID:

```sh
kubectl -n outpost get teamenvironment scout-env -o jsonpath='{.metadata.uid}{"\n"}'
kubectl -n outpost get configmap -l team=outpost \
  -o custom-columns='NAME:.metadata.name,OWNER:.metadata.ownerReferences[*].name'
```

The three ConfigMaps share the label `team: outpost`, and none has an owner. A label does not make the garbage collector delete anything. Only `scout-env-settings` and `scout-env-limits` belong to the environment.

---

## Step 6: Add the owner reference

Replace `<TEAM_ENV_UID>` with the UID you printed in both places. A reference to a UID that does not exist makes the garbage collector delete the ConfigMap, so copy the value exactly. Save this as `configmap-env-owner.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: scout-env-settings
  namespace: outpost
  labels:
    team: outpost
  ownerReferences:
    - apiVersion: platform.starfleet.io/v1alpha1
      kind: TeamEnvironment
      name: scout-env
      uid: <TEAM_ENV_UID>
      blockOwnerDeletion: true
data:
  mode: small
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: scout-env-limits
  namespace: outpost
  labels:
    team: outpost
  ownerReferences:
    - apiVersion: platform.starfleet.io/v1alpha1
      kind: TeamEnvironment
      name: scout-env
      uid: <TEAM_ENV_UID>
      blockOwnerDeletion: true
data:
  mode: small
```

Apply it:

```sh
kubectl apply -f configmap-env-owner.yaml
```

Then check the result:

```sh
kubectl -n outpost get configmap -l team=outpost \
  -o custom-columns='NAME:.metadata.name,OWNER:.metadata.ownerReferences[*].name'
```

Only the two environment ConfigMaps show the owner `scout-env`. Check the watch terminal. `ownership` passes.

---

## Step 7: Find why scout-settings stays

Read the deletion fields of the ConfigMap:

```sh
kubectl -n outpost get configmap scout-settings \
  -o jsonpath='deletionTimestamp={.metadata.deletionTimestamp} finalizers={.metadata.finalizers}{"\n"}'
```

The deletion timestamp is set and the finalizer `platform.starfleet.io/cleanup` is still there. The API server waits for the component that implements the finalizer. The annotation `platform.starfleet.io/cleanup-job` names it. Look at that Job and at what its ServiceAccount may do:

```sh
kubectl -n outpost get job scout-cleanup -o custom-columns=NAME:.metadata.name,SUSPEND:.spec.suspend,ACTIVE:.status.active
kubectl -n outpost auth can-i delete configmap/scout-cache --as=system:serviceaccount:outpost:scout-cleanup
kubectl -n outpost auth can-i patch configmap/scout-settings --as=system:serviceaccount:outpost:scout-cleanup
```

The Job is suspended, so no pod runs. The ServiceAccount can patch `scout-settings` but cannot delete `scout-cache`. Two causes exist. If you start the Job first, its second container fails with a `forbidden` error, and the Job ends as failed. Fix the permission first.

---

## Step 8: Grant the one missing permission

Read the Role and add `delete` to the rule for `scout-cache` only. Keep `resourceNames`. Save this as `role-scout-cleanup.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scout-cleanup
  namespace: outpost
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    resourceNames: ["scout-settings"]
    verbs: ["get", "list", "watch", "patch"]
  - apiGroups: [""]
    resources: ["configmaps"]
    resourceNames: ["scout-cache"]
    verbs: ["get", "list", "watch", "delete"]
```

Apply it:

```sh
kubectl apply -f role-scout-cleanup.yaml
```

Then check the result:

```sh
kubectl -n outpost auth can-i delete configmap/scout-cache --as=system:serviceaccount:outpost:scout-cleanup
kubectl -n outpost auth can-i delete configmaps --as=system:serviceaccount:outpost:scout-cleanup
```

The first command prints `yes` and the second prints `no`. Check the watch terminal. `cleanup-access` passes.

---

## Step 9: Start the cleanup worker

The Job template cannot be changed, but `spec.suspend` can. Resume the Job and wait for it:

```sh
kubectl -n outpost patch job scout-cleanup --type merge -p '{"spec":{"suspend":false}}'
kubectl -n outpost wait --for=condition=Complete --timeout=180s job/scout-cleanup
kubectl -n outpost logs job/scout-cleanup --all-containers=true
```

The first container sees the deletion timestamp, the second deletes `scout-cache`, and the main container removes the finalizer only after that. Confirm that both ConfigMaps are gone and that `shared-notes` remains:

```sh
kubectl -n outpost get configmap
```

Check the watch terminal. `cleanup-done` passes.

---

## Step 10: Submit

When all five checks pass, press Ctrl-C to stop the watch and run the submit command once:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## If a check stays red

- **`prometheus-reconciled` fails with "deleted and created again".** You replaced the resource. The grader compares the UID with the one recorded at the start. Reset the lab and patch the original.
- **`prometheus-reconciled` fails on `additionalScrapeConfigs`.** You removed the reference to silence the error. Put it back (`name: extra-scrape`, `key: jobs.yaml`) and create the Secret.
- **`prometheus-identity` fails on a missing list permission.** The ServiceAccount has no access. Use `prometheus`, not a new ServiceAccount.
- **`ownership` fails with the ConfigMap missing.** The UID in the reference did not match a real object, and the garbage collector deleted the ConfigMap. Reset the lab and copy the UID exactly.
- **`ownership` fails on `shared-notes`.** You gave every ConfigMap with the label an owner. Remove the reference from `shared-notes`.
- **`cleanup-done` fails because the Job is not Complete.** Read its conditions and the logs of its pod. If the Job failed because you started it before fixing the Role, it has used its one retry and stays failed. Run `astrona destroy ats-019-capstone-020`, start the lab again and fix the Role before you resume the Job.
- **`cleanup-done` fails because the Job is missing.** The Job only completes while `scout-settings` is still in Terminating. If you removed the finalizer by hand, the Job cannot run any more. Run `astrona destroy ats-019-capstone-020`, start the lab again and use the Job.
- **`cleanup-access` fails on wide access.** You allowed deleting all ConfigMaps or bound `cluster-admin`. Use `resourceNames` for exactly `scout-cache` and `scout-settings`.
