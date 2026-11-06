# Solution Walkthrough

Trace the request on `terminal`, record the failing child's condition, then
repair the Composition. A composite resource is one object of a platform
application programming interface (API);
a composed resource is an object Crossplane creates for that request.

| Goal | Where it lives | Command or field |
| --- | --- | --- |
| Find the failing child | Resource tree | `crossplane resource trace -o wide` |
| Keep the original diagnosis | ConfigMap `trace-report` | `data.reason`, `data.message` |
| Repair the source | Composition `teamenvironment` | `spec.providerConfigRef` in the Service Object base |
| Confirm recovery | Live status conditions | `kubectl wait` |

## The feedback loop

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-03/labs/lab-04
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

The checks are `diagnosis` and `request-ready`. Both should fail at the start.

## Step 1: Find the failing child

Run on `terminal`. Add the installed binary directory to this shell's search path:

```sh
export PATH="/workspace/bin:$PATH"
crossplane resource trace teamenvironment scout-env -n outpost
crossplane resource trace teamenvironment scout-env -n outpost -o wide
```

Find the `Object` row with `SYNCED` set to `False`. The `RESOURCE` column
identifies the Composition resource `service`. Read the complete `STATUS`
message; it names a provider configuration that does not exist.

Read the child's conditions directly. Replace `<OBJECT_NAME>` with the
exact generated name from that row:

```sh
kubectl -n outpost get objects.kubernetes.m.crossplane.io <OBJECT_NAME> -o jsonpath='{range .status.conditions[*]}{.type}{"  "}{.status}{"  "}{.reason}{"  "}{.message}{"\n"}{end}'
```

Copy the `reason` and `message` from the `Synced` condition. The trace reads
these same fields. **Check the watch terminal.** Neither check passes yet.

## Step 2: Save the original diagnosis

A ConfigMap stores named text values. Save this as `configmap-trace-report.yaml`.
Replace all three placeholders with the live values you just read. Keep the
full message on one line; the `|-` block marker removes the final newline:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: trace-report
  namespace: outpost
data:
  kind: Object
  name: <OBJECT_NAME>
  reason: <SYNCED_REASON>
  message: |-
    <FULL_SYNCED_MESSAGE>
```

`kind` and `name` identify the managed resource, rather than the wrapped
Service. `reason` is the short condition reason. `message` preserves the
full explanation of the original fault.

Apply it:

```sh
kubectl apply -f configmap-trace-report.yaml
```

**Check the watch terminal.** `diagnosis` passes. Preserve the report while
repairing the fault; a successful reconcile replaces the failing condition.

## Step 3: Repair the Composition and wait for readiness

Read the available provider configurations, then edit the Composition:

```sh
kubectl get clusterproviderconfigs.kubernetes.m.crossplane.io
kubectl edit composition teamenvironment
```

Under `spec.pipeline[0].input.resources`, find the entry named `service`.
In that entry's `base.spec.providerConfigRef`, keep
`kind: ClusterProviderConfig` and change `name: outpost-missing` to
`name: in-cluster`. Save and close the editor. Editing the Composition
repairs the desired state that Crossplane applies to the existing child.

Wait for the controllers to reconcile, then trace the request again:

```sh
kubectl -n outpost wait teamenvironment/scout-env --for=condition=Ready --timeout=600s
kubectl -n outpost wait teamenvironment/scout-env --for=condition=Synced --timeout=120s
crossplane resource trace teamenvironment scout-env -n outpost -o wide
```

Look for `True` in both condition columns on the request and both children.
**Check the watch terminal.** `diagnosis` and `request-ready` pass.

If `diagnosis` fails, compare the report with the values you copied before
repair. Do not replace them with the healthy condition. If `request-ready`
fails, check that you edited the `service` entry in the Composition, then
read the failing child's full message again.

## Step 4: Submit

Press Ctrl-C to stop the watch, then run the submit command once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-03/labs/lab-04
```

The final grading checks both the saved diagnosis and the live readiness.
