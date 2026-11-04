# Solution Walkthrough

You work on the `terminal` of the lab cluster. You give the ConfigMap `probe-data` a new owner, delete the old owner without losing the ConfigMap, and then delete the second owner so that Kubernetes removes its dependent.

| Goal | Where it lives | Command or field |
| --- | --- | --- |
| Link a dependent to its owner | `metadata.ownerReferences` of the dependent | `kind`, `name` and the real `uid` of the owner |
| Replace the whole list of owners | a JSON merge patch | `kubectl patch --type=merge` |
| Delete an owner and keep its dependents | the delete request | `--cascade=orphan`, or give the dependent a new owner first |
| Delete an owner and its dependents | the garbage collector | `--cascade=background` or `--cascade=foreground` |

## The feedback loop

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch -c sections/section-020/module-02/labs/lab-01
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

The grader has two checks: `probe-handover` and `owner-cascade`. Both fail at the start. The watch terminal shows each check as it turns green.

---

## Step 1: Read the start state

List the owners and the owner references of the ConfigMaps:

```sh
kubectl -n outpost get teamenvironment
kubectl -n outpost get configmap -l team=outpost -o custom-columns='NAME:.metadata.name,OWNER:.metadata.ownerReferences[*].name,UID:.metadata.ownerReferences[*].uid'
```

Two `TeamEnvironment` objects exist: `scout-env` and `probe-env`. The ConfigMap `scout-config` has the owner `scout-env`, `probe-data` has the owner `probe-env`, and `scout-unowned` has no owner. The label `team=outpost` is on all three, but a label does not link objects. No check turns green in this step.

If you delete `probe-env` now, the garbage collector deletes `probe-data` too. That is the trap of this lab.

---

## Step 2: Create the new owner

Save this as `teamenvironment-probe-env-v2.yaml`:

```yaml
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: probe-env-v2
  namespace: outpost
spec:
  team: outpost
  size: medium
```

Apply it:

```sh
kubectl apply -f teamenvironment-probe-env-v2.yaml
```

Read its UID. You need it in the next step:

```sh
kubectl -n outpost get teamenvironment probe-env-v2 -o jsonpath='{.metadata.uid}{"\n"}'
```

No check turns green in this step.

---

## Step 3: Move probe-data to the new owner

Save this as `patch-probe-data.yaml`. Replace `<PROBE_ENV_V2_UID>` with the UID you just read:

```yaml
metadata:
  ownerReferences:
    - apiVersion: platform.starfleet.io/v1alpha1
      kind: TeamEnvironment
      name: probe-env-v2
      uid: <PROBE_ENV_V2_UID>
      blockOwnerDeletion: true
```

- `kind` and `name` say which owner this is.
- `uid` identifies this exact object. An owner with the same name but a different UID is a different owner.
- `blockOwnerDeletion: true` lets this dependent block foreground deletion of its owner.

Apply the patch with the merge strategy:

```sh
kubectl -n outpost patch configmap probe-data --type=merge --patch-file patch-probe-data.yaml
```

A JSON merge patch replaces the whole `ownerReferences` list, so the old reference to `probe-env` is gone. The default strategic merge patch for this field merges entries by `uid` and would keep the old reference as a second owner. Check the result:

```sh
kubectl -n outpost get configmap probe-data -o custom-columns='NAME:.metadata.name,OWNER:.metadata.ownerReferences[*].name'
```

Only `probe-env-v2` is listed as owner. No check turns green yet, because `probe-env` still exists.

---

## Step 4: Delete the old owner

`probe-data` no longer depends on `probe-env`, so deleting `probe-env` leaves it alone:

```sh
kubectl -n outpost delete teamenvironment probe-env --cascade=background --timeout=60s
kubectl -n outpost get configmap probe-data
```

The ConfigMap `probe-data` is still there. Check the watch terminal. `probe-handover` now passes.

> You can reach the same end state in another order: delete `probe-env` with `--cascade=orphan` first, which removes the reference to it and keeps `probe-data`, and then add the reference to `probe-env-v2` with the patch from step 3. The grader accepts both orders.

---

## Step 5: Delete the second owner

`scout-config` has an owner reference to `scout-env`, so the garbage collector deletes it when its owner goes. Delete the owner and wait for the dependent:

```sh
kubectl -n outpost delete teamenvironment scout-env --cascade=foreground --timeout=60s
kubectl -n outpost wait --for=delete configmap/scout-config --timeout=60s
kubectl -n outpost get configmap -l team=outpost
```

`scout-config` is gone. `probe-data` and `scout-unowned` remain, because only `scout-config` had `scout-env` as its owner. Check the watch terminal. `owner-cascade` now passes.

---

## Step 6: Submit

When both checks are green, press Ctrl-C to stop the watch and run the submit command once:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

---

## If a check stays red

- **`probe-handover` fails with "probe-data is gone".** You deleted `probe-env` while `probe-data` still pointed to it, or you deleted by label. The grader cannot restore it. Destroy the lab and start again, and move the ownership first.
- **`probe-handover` fails with "was recreated".** You deleted `probe-data` and created a ConfigMap with the same name. The UID of the new object differs from the original. Start again.
- **`probe-handover` fails with "exactly one owner reference".** The list still holds the old reference, or you used the default strategic patch. Apply the patch from step 3 with `--type=merge`.
- **`probe-handover` fails with "UID of probe-env-v2".** You copied the UID of `probe-env`, or of an earlier `probe-env-v2` that you deleted and created again. Read the UID from the object that exists now.
- **`owner-cascade` fails with "scout-unowned was deleted".** You deleted the ConfigMaps with `-l team=outpost`. A shared label is not ownership. Start again.
- **`owner-cascade` fails with "scout-config still exists".** The owner `scout-env` is not deleted yet, or it is still terminating. Check `kubectl -n outpost get teamenvironment`, wait a few seconds and check the watch terminal again.
