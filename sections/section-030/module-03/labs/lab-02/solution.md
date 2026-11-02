# Solution Walkthrough

You trace the request first, then fix the Composition. You never touch the
composed objects. Crossplane re-reads the Composition and repairs them.

| Goal | Where it lives | Command |
| --- | --- | --- |
| Find the failing resource | The `Object` resources the request lists | `crossplane resource trace`, `kubectl describe` |
| Fix the ProviderConfig name | `service` resource in the Composition | `kubectl edit composition teamenvironment` |
| Fix the replicas patch | `deployment` resource patches | `kubectl edit composition teamenvironment` |
| Prove the workload | A request from `shuttle` | `kubectl -n outpost exec deploy/shuttle -- curl ...` |

## The feedback loop

Run this from the terminal where you typed `astrona run`, after every step:

```sh
astrona submit -c sections/section-030/module-03/labs/lab-02
```

The checks are `composition`, `request-ready`, `workload-follows-request`,
`answers` and `no-shortcuts`. At the start, `no-shortcuts` can pass and the
others fail.

---

## Step 1: Trace the request

Read the state of the request and its composed resources. The `crossplane` CLI
is in `/workspace/bin`, so call it with its full path or add that folder to
your `PATH`:

```sh
kubectl -n outpost get teamenvironment scout-env
/workspace/bin/crossplane resource trace teamenvironment scout-env -n outpost
kubectl -n outpost get objects.kubernetes.m.crossplane.io
```

The trace shows the composed `Object` resources. At least one of them is not
`Ready`. Describe it and read the `Synced` condition and the events:

```sh
kubectl -n outpost describe objects.kubernetes.m.crossplane.io
```

The message names a ProviderConfig that cannot be found. The name is
`in-clustr`, a misspelling of `in-cluster`. No check turns green yet.

---

## Step 2: Fix the ProviderConfig name

Open the Composition:

```sh
kubectl edit composition teamenvironment
```

In the resource named `service`, change `providerConfigRef.name` from
`in-clustr` to `in-cluster`. Save and close the editor.

**Run the check.** The check `composition` is still red, because the second
fault is open.

---

## Step 3: Fix the replicas patch

A patch with a wrong source path does not stop the request. The request can
become `Ready` while the Deployment ignores `spec.replicas`. Compare the patch
with the field name in the XRD:

```sh
kubectl get xrd teamenvironments.platform.starfleet.io -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties}'
```

The request field is `replicas`, not `replica`. Open the Composition again:

```sh
kubectl edit composition teamenvironment
```

In the resource named `deployment`, set the patch to `fromFieldPath:
spec.replicas` and `toFieldPath: spec.forProvider.manifest.spec.replicas`. Save
and close the editor.

**Run the check.** The check `composition` passes.

---

## Step 4: Wait for the request

Crossplane reconciles the request again after the Composition changes:

```sh
kubectl -n outpost wait teamenvironment/scout-env --for=condition=Ready --timeout=300s
kubectl -n outpost get deployment scout
kubectl -n outpost exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://scout:9898
```

The Deployment shows 2 ready replicas and the request returns `200`. If the
status is `000`, the pods are still starting. Run the command again.

**Run the check.** The checks `request-ready`, `workload-follows-request` and
`answers` pass. The check `no-shortcuts` passes too, if you did not create
objects by hand.

---

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-03/labs/lab-02
```

---

## If a check stays red

- **`composition` says the service uses another ProviderConfig.** The name is
  still misspelled. Read it again with `kubectl get composition
  teamenvironment -o yaml`.
- **`composition` says no patch copies `spec.replicas`.** The `fromFieldPath`
  or the `toFieldPath` of the `deployment` patch differs from the exact paths
  in the task.
- **`request-ready` says the request was changed.** Do not edit `scout-env`.
  Restore `team: outpost`, `replicas: 2` and the Composition
  `teamenvironment`.
- **`workload-follows-request` says replicas differ.** The Deployment is not
  updated yet. Wait, and check that the patch is correct. Do not scale the
  Deployment by hand.
- **`no-shortcuts` fails.** You created a second ProviderConfig, widened the
  RBAC rules or created an `Object` by hand. Remove it, and fix the
  Composition instead.
