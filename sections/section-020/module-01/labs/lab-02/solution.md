# Solution Walkthrough

You work on the `terminal` of the lab cluster. You read the conditions of the `Prometheus` resource, the events of the StatefulSet and the log of the operator, and you fix two causes: a missing Secret and a missing ServiceAccount. You do not delete the `Prometheus` resource.

| Goal | Where it lives | Command or object |
| --- | --- | --- |
| Find out whether the operator finished | `status.conditions` of the `Prometheus` resource | `Reconciled` status, reason and message |
| Find out why the pod does not exist | Events of the owned StatefulSet | `kubectl get events --field-selector involvedObject.name=prometheus-tenant` |
| See the operator's own error | The operator log | `kubectl -n default logs deploy/prometheus-operator` |
| Fix the causes | What the resource references | The Secret `tenant-scrape` and the field `spec.serviceAccountName` |

## The feedback loop

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch -c sections/section-020/module-01/labs/lab-02
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

The grader has three checks: `scrape-secret`, `reconciled` and `service-account`. At the start, all three fail. The watch terminal shows each check as it turns green.

---

## Step 1: Read the conditions

Print the conditions with their reason and message:

```sh
kubectl -n outpost get prometheus tenant \
  -o jsonpath='{range .status.conditions[*]}{.type}{" "}{.status}{" reason="}{.reason}{" message="}{.message}{"\n"}{end}'
```

`Reconciled` is `False` with the reason `ReconciliationFailed`. The message says the operator could not load the additional scrape configuration because a Secret was not found. The operator log shows the same error with the key `outpost/tenant`:

```sh
kubectl -n default logs deploy/prometheus-operator --since=10m | grep 'outpost/tenant' | tail -1
```

No check turns green in this step.

---

## Step 2: Create the Secret

The `Prometheus` resource names the Secret `tenant-scrape` and the key `jobs.yaml`. Save this as `secret-tenant-scrape.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: tenant-scrape
  namespace: outpost
stringData:
  jobs.yaml: |
    - job_name: scout-extra
      static_configs:
        - targets: ["scout.outpost.svc:9898"]
```

Apply it:

```sh
kubectl apply -f secret-tenant-scrape.yaml
```

The operator watches Secrets, so the new Secret starts a reconcile. Read the conditions again after a few seconds. `Reconciled` is now `True`. The check `scrape-secret` passes.

---

## Step 3: Follow the chain to the pod

`Reconciled True` means the operator built its objects. `Available` is still `False`. The built-in StatefulSet controller creates the pod, so read the events of the StatefulSet:

```sh
kubectl -n outpost get statefulset prometheus-tenant
kubectl -n outpost get events --field-selector involvedObject.name=prometheus-tenant \
  -o custom-columns=TYPE:.type,REASON:.reason,MESSAGE:.message
```

The StatefulSet has no ready pod. A `FailedCreate` event says that the ServiceAccount `prometheus-tenant` was not found. The `Prometheus` resource names it in `spec.serviceAccountName`, and it does not exist. No check turns green in this step.

---

## Step 4: Use the ServiceAccount that has the access

The ServiceAccount `prometheus` in `outpost` is bound to a ClusterRole with read access to Pods, Services and Endpoints. Point the `Prometheus` resource at it, and wait:

```sh
kubectl -n outpost patch prometheus tenant --type merge -p '{"spec":{"serviceAccountName":"prometheus"}}'
kubectl -n outpost wait --for=condition=Available --timeout=300s prometheus/tenant
```

Creating an empty ServiceAccount named `prometheus-tenant` would also start the pod, and `Available` would turn `True`. But that ServiceAccount has no RBAC, so Prometheus could not read any target. The check `service-account` rejects it.

---

## Step 5: Submit

Press Ctrl-C to stop the watch, then run the submit command once:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-02
```

## If a check stays red

- **`scrape-secret` fails.** The Secret name, the key or the job is not exactly as the task says. Check `job_name: scout-extra` and the target `scout.outpost.svc:9898`.
- **`reconciled` fails with `Available=False`.** The pod can take a minute to start after the fix. Run `kubectl -n outpost get pods` and read the watch terminal again.
- **`service-account` fails with a `cannot` message.** The ServiceAccount has no read access. Use `prometheus`, or bind a new ServiceAccount to the ClusterRole `outpost-prometheus`.
- **`service-account` fails with a `can` message.** The ServiceAccount has too much access. Remove the wide binding.
