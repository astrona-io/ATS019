# Choose A Cascading Deletion Mode

A platform team sometimes wants to wait for cleanup, and sometimes wants to keep resources after removing a request. Cascading deletion is the deletion of an owner's dependent objects. Kubernetes lets you choose the policy on each delete request. The examples use a `TeamEnvironment` custom resource, an object of a type added to the Kubernetes application programming interface (API), and a ConfigMap that stores non-secret data.

## Wait for dependents with foreground deletion

An owner reference links a dependent to its owner's unique identifier (UID). The garbage collector is a Kubernetes controller that deletes dependents whose owners are gone. The playground's `TeamEnvironment` type has no application controller, so nothing recreates its dependents after deletion.

<!-- astrona:playground:renew -->

Save this as `teamenvironment-probe-env.yaml`:

```yaml
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: probe-env
  namespace: outpost
spec:
  team: outpost
  size: small
```

Apply it:

```sh
kubectl apply -f teamenvironment-probe-env.yaml
```

You should see:

```text
teamenvironment.platform.starfleet.io/probe-env created
```

Then read the UID:

```sh
TEAM_ENV_UID=$(kubectl -n outpost get teamenvironment probe-env -o jsonpath='{.metadata.uid}')
echo "$TEAM_ENV_UID"
```

You should see:

```text
237cd069-d55e-49fa-bfa6-62eedecb3148
```

Your UID differs. Replace `<TEAM_ENV_UID>` below with that value. Save this as `configmap-probe-owned.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: probe-owned
  namespace: outpost
  labels:
    team: outpost
  ownerReferences:
    - apiVersion: platform.starfleet.io/v1alpha1
      kind: TeamEnvironment
      name: probe-env
      uid: <TEAM_ENV_UID>
      blockOwnerDeletion: true
data:
  mode: small
```

Apply it:

```sh
kubectl apply -f configmap-probe-owned.yaml
```

You should see:

```text
configmap/probe-owned created
```

Now delete the owner with foreground cascading deletion and check both objects:

```sh
kubectl -n outpost delete teamenvironment probe-env --cascade=foreground --timeout=60s
kubectl -n outpost get teamenvironment probe-env --ignore-not-found -o name
kubectl -n outpost get configmap probe-owned --ignore-not-found -o name
```

You should see:

```text
teamenvironment.platform.starfleet.io "probe-env" deleted from outpost namespace
```

The two checks print nothing because both objects are gone. Foreground deletion keeps the owner visible until the garbage collector removes the dependents that block its deletion. Kubernetes sets `metadata.deletionTimestamp` on the owner and adds the built-in `foregroundDeletion` finalizer while that work runs. A finalizer is a name that prevents the API server from removing an object until the responsible component releases it.

Only dependents known to the garbage collector with `blockOwnerDeletion: true` block foreground owner deletion. The garbage collector removes its own finalizer after those blocking dependents are gone. If one of them has a custom finalizer that cannot finish, the owner can stay in a terminating state too. Inspect both the owner and its dependents when a foreground delete waits too long.

## Keep dependents with orphan deletion

Recreate the owner from the same file and read its new UID:

```sh
kubectl apply -f teamenvironment-probe-env.yaml
TEAM_ENV_UID=$(kubectl -n outpost get teamenvironment probe-env -o jsonpath='{.metadata.uid}')
echo "$TEAM_ENV_UID"
```

You should see:

```text
teamenvironment.platform.starfleet.io/probe-env created
30afd50a-c0ba-4bc9-b6ea-60171752acce
```

The name is the same, but the UID is new. Replace the old UID in `configmap-probe-owned.yaml` with this new value. Apply it:

```sh
kubectl apply -f configmap-probe-owned.yaml
```

You should see:

```text
configmap/probe-owned created
```

Then delete the owner while keeping its dependent:

```sh
kubectl -n outpost delete teamenvironment probe-env --cascade=orphan --timeout=60s
kubectl -n outpost get configmap probe-owned -o custom-columns=NAME:.metadata.name,OWNERS:.metadata.ownerReferences
```

You should see:

```text
teamenvironment.platform.starfleet.io "probe-env" deleted from outpost namespace
NAME          OWNERS
probe-owned   <none>
```

The ConfigMap still exists and its owner references are empty. Orphan deletion removes the reference to the deleted owner rather than deleting this dependent. If a dependent has other owners, their references remain. Keeping an object does not give it a new controller or a new cleanup policy; the platform team must decide what should manage it now.

For an operator-managed workload, orphaning also removes the request that the operator used to update it. A retained StatefulSet may still manage its pods, but the Prometheus Operator no longer has that deleted `Prometheus` request to reconcile. Treat orphaning as a deliberate handover, not a routine way to avoid cleanup errors.

## Choose the policy for the task

Background deletion removes the owner without waiting for dependent cleanup, unless the owner has finalizers of its own. The garbage collector then deletes dependents asynchronously. It is the default policy for `kubectl delete`; specifying it explicitly makes your intent clear.

| Policy | Flag | What happens to dependents | When to choose it |
| --- | --- | --- | --- |
| Background | `--cascade=background` | Deleted asynchronously | Routine deletion where dependent cleanup can finish later |
| Foreground | `--cascade=foreground` | Blocking dependents go before the owner | Wait for the known ownership chain to be removed |
| Orphan | `--cascade=orphan` | Retained, with this owner's reference removed | Preserve resources for a planned handover |

`--wait=false` is a different choice: it tells the client to return after the delete request is accepted. It does not change the cascading policy or bypass finalizers. The default wait watches the named owner, so background deletion returning successfully does not prove that every dependent is gone.

Remove the two intentionally retained ConfigMaps:

```sh
kubectl -n outpost delete configmap probe-owned scout-unowned
```

You should see:

```text
configmap "probe-owned" deleted from outpost namespace
configmap "scout-unowned" deleted from outpost namespace
```

You can now choose whether cleanup runs after the owner disappears, blocks the owner's deletion, or leaves dependents for a new owner. The foreground and orphan examples used the same manifests; only the delete policy changed their lifecycle. A separate question remains when deletion is accepted but an object never disappears: which finalizer is still waiting?

## Common pitfalls

> [!WARNING]
> - **Reusing an old UID after recreating the owner.** Update the dependent's reference before applying it again.
> - **Treating background deletion as proof of full cleanup.** Wait for or inspect the dependent objects too.
> - **Using orphan deletion to fix a failed cleanup.** It preserves resources and transfers cleanup responsibility to you.
> - **Confusing `--wait=false` with orphan deletion.** Waiting controls the client; cascading controls the dependents.
