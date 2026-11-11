# Solution Walkthrough

A normal delete of a composite resource removes everything it owns. To keep the
workload, you delete the request with `--cascade=orphan`. The Kubernetes garbage collector removes the owner references from the
dependents instead of deleting them. First pause Crossplane reconciliation
and wait for its acknowledgement, so composition cannot restore ownership
while the garbage collector removes it.

| Goal | Where it lives | Command |
| --- | --- | --- |
| See what the request owns | `spec.crossplane.resourceRefs` | `kubectl -n outpost get teamenvironment scout-env -o yaml` |
| Delete without deleting dependents | The `--cascade` option | `kubectl delete --cascade=orphan` |
| Prove the workload stayed | Deployment, Service and `Object` resources | `kubectl -n outpost get ...` |
| Prove it answers | A request from `shuttle` | `kubectl -n outpost exec deploy/shuttle -- curl ...` |

## The feedback loop

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch -c sections/section-030/module-03/labs/lab-03
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

The checks are `request-gone`, `workload-kept`, `objects-orphaned` and
`answers`. At the start `workload-kept` and `answers` can pass. The request still exists
and still owns the Objects, so the other two checks fail.

---

## Step 1: Look at what the request owns

```sh
kubectl -n outpost get teamenvironment scout-env
kubectl -n outpost get objects.kubernetes.m.crossplane.io
kubectl -n outpost get deployment,service scout
```

The request is `Ready`. Two `Object` resources exist, and so do the Deployment
and the Service named `scout`. Do not delete anything yet.

---

## Step 2: Delete the request with orphaning

```sh
kubectl -n outpost annotate teamenvironment scout-env crossplane.io/paused=true --overwrite
kubectl -n outpost wait teamenvironment/scout-env --for=jsonpath='{.status.conditions[?(@.type=="Synced")].reason}'=ReconcilePaused --timeout=180s
kubectl -n outpost delete teamenvironment scout-env --cascade=orphan --wait=false
for attempt in $(seq 1 90); do
  finalizers=$(kubectl -n outpost get teamenvironment scout-env -o jsonpath='{.metadata.finalizers[*]}')
  [ "$finalizers" = composite.apiextensions.crossplane.io ] && break
  sleep 2
done
[ "$finalizers" = composite.apiextensions.crossplane.io ] || { echo 'Orphan processing did not finish; keep reconciliation paused' >&2; exit 1; }
kubectl -n outpost annotate teamenvironment scout-env crossplane.io/paused-
kubectl -n outpost wait --for=delete teamenvironment/scout-env --timeout=180s
```

Wait for `ReconcilePaused` before requesting orphan deletion. Use `--wait=false`
so the shell can wait for orphan processing before resuming Crossplane. In this
fixture, only `composite.apiextensions.crossplane.io` remains after the garbage
collector removes its `orphan` finalizer and detaches the dependents. Resuming
earlier can race with that process and delete the workload. Crossplane must
then resume to remove its own finalizer; leaving it paused would keep the
request in deletion. The last command waits for the request to disappear.
Do not remove finalizers by hand.

**Check the watch terminal.** The checks `request-gone`, `workload-kept` and
`objects-orphaned` pass.

---

## Step 3: Prove the workload still answers

```sh
kubectl -n outpost get objects.kubernetes.m.crossplane.io
kubectl -n outpost exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://scout:9898
```

The `Object` resources remain, and the request returns `200`. The `Object`
resources no longer have a composite owner, but `provider-kubernetes` still
reconciles them and manages their Deployment and Service. Leave them in place.

**Check the watch terminal.** All four checks pass.

---

## Step 4: Submit

Press Ctrl-C to stop the watch, then run the submit command once:

```sh
astrona submit -c sections/section-030/module-03/labs/lab-03
```

---

## If a check stays red

- **`request-gone` fails.** The delete is not finished, or the command did not
  run. Check with `kubectl -n outpost get teamenvironment`. If deletion is
  requested but paused, first wait for the `orphan` finalizer to disappear,
  then remove `crossplane.io/paused` so Crossplane can finalize it.
- **`workload-kept` fails.** You deleted without `--cascade=orphan`, so
  Crossplane removed the Deployment and the Service. This lab cannot be
  repaired in place. Run `astrona destroy ats-019-lab-030-03-03` and start
  again. A Deployment recreated by hand fails this check on purpose, because it
  has a new UID.
- **`objects-orphaned` fails.** An `Object` was deleted, or it still has an
  owner reference. Start again and use `--cascade=orphan`.
- **`answers` fails.** Wait a few seconds and send the request again.
