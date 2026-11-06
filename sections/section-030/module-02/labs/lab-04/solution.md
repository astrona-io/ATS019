# Solution Walkthrough

Create a request from the existing API, then add one native Service template
to its Composition. A composite resource (XR) is a request that Crossplane
reconciles into the resources returned by its composition function. A
Composition defines that function pipeline and its resource templates.

| Goal | Field or object | Reason |
| --- | --- | --- |
| Select the Composition | `spec.crossplane.compositionRef` | Use the supplied platform implementation |
| Adopt changes | `compositionUpdatePolicy: Automatic` | Follow newer Composition revisions |
| Select the Pods | `spec.selector.app` | Match the StatefulSet Pod labels |
| Check the Service | `NonEmpty` on `spec.clusterIP` | Observe Kubernetes assigning its address |
| Prove identity | `metadata.uid` | A recreated object receives a different UID |

## The feedback loop

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-02/labs/lab-04
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

Initially, expect all four checks to fail: `tenant-request`,
`composition-extended`, `existing-request-updated` and `services-reach-pods`.
The setup supplies a working original workload but no client Service.

## Step 1: Read the existing API and record identity

A CompositeResourceDefinition (XRD) defines the schema of the request.
Read it and the existing Composition before changing anything:

```sh
kubectl get xrd teamenvironments.platform.starfleet.io -o yaml
kubectl get composition scout-stateful -o yaml
kubectl -n outpost get teamenvironment outpost-scout -o jsonpath='{.metadata.uid}{"\n"}{.spec.crossplane.compositionRevisionRef.name}{"\n"}'
kubectl -n outpost get statefulset outpost-scout -o jsonpath='{.metadata.uid}{"\n"}'
kubectl -n outpost get service outpost-scout-pods -o jsonpath='{.metadata.uid}{"\n"}'
```

Note the three UIDs and the revision name. A UID is the unique identifier
Kubernetes assigns when it creates an object. The two templates create a
headless Service for Pod network identity and a one-replica StatefulSet.
The StatefulSet check uses `NonEmpty` on `status.readyReplicas`: the API
server leaves that field out while no Pod is ready, so the check passes once
one Pod is ready. No grading check changes yet.

## Step 2: Consume the existing XRD

Save this as `teamenvironment-outpost-probe.yaml`:

```yaml
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: outpost-probe
  namespace: outpost
spec:
  team: probe
  crossplane:
    compositionRef:
      name: scout-stateful
    compositionUpdatePolicy: Automatic
```

`apiVersion` and `kind` select the API defined by the XRD. `metadata` names
the request and its namespace. `team` supplies the schema's required field.
`compositionRef` selects the existing Composition. `Automatic` permits the
request to adopt new revisions of that Composition.

Apply it:

```sh
kubectl apply -f teamenvironment-outpost-probe.yaml
```

Wait for the request to become ready:

```sh
kubectl -n outpost wait teamenvironment/outpost-probe --for=condition=Ready --timeout=300s
```

**Check the watch terminal:** it shows `tenant-request` passing
once the new StatefulSet is ready. Both requests still lack a client Service.

## Step 3: Append the Service template

Export the live Composition to your working folder:

```sh
kubectl get composition scout-stateful -o yaml > composition-scout-stateful.yaml
```

Open `composition-scout-stateful.yaml` in your editor. Leave the two existing
entries unchanged. Append the following entry to
`spec.pipeline[0].input.resources`, at the same indentation as
`- name: governing-service` and `- name: statefulset`.
Save this as the updated `composition-scout-stateful.yaml`:

```yaml
          - name: service
            base:
              apiVersion: v1
              kind: Service
              metadata: {}
              spec:
                type: ClusterIP
                selector: {}
                ports:
                  - port: 9898
                    targetPort: 9898
            patches:
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.name
                toFieldPath: metadata.name
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.namespace
                toFieldPath: metadata.namespace
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.name
                toFieldPath: spec.selector.app
            readinessChecks:
              - type: NonEmpty
                fieldPath: spec.clusterIP
```

`name: service` identifies the new template within the pipeline. `base`
describes a native Kubernetes Service. `type: ClusterIP` asks for an internal
address, and both port fields use `9898`. The three patches copy the XR name,
namespace and name into the Service name, namespace and Pod selector.
`readinessChecks` belongs to the resource entry, beside `patches` and `base`.
`NonEmpty` checks `spec.clusterIP` on the observed native Service.

Apply it:

```sh
kubectl apply -f composition-scout-stateful.yaml
```

**Check the watch terminal:** it shows `composition-extended`
passing. Crossplane creates a new Composition revision; allow time for both
requests to adopt it and for their new Services to appear.

## Step 4: Prove the existing request gained its Service

Read the same identity fields again and inspect the new Services:

```sh
kubectl -n outpost get teamenvironment outpost-scout -o jsonpath='{.metadata.uid}{"\n"}{.spec.crossplane.compositionRevisionRef.name}{"\n"}'
kubectl -n outpost get statefulset outpost-scout -o jsonpath='{.metadata.uid}{"\n"}'
kubectl -n outpost get service outpost-scout-pods -o jsonpath='{.metadata.uid}{"\n"}'
kubectl -n outpost get teamenvironment outpost-scout outpost-probe
kubectl -n outpost get service outpost-scout outpost-probe -o yaml
kubectl -n outpost get endpointslices -l kubernetes.io/service-name=outpost-scout -o yaml
kubectl -n outpost get endpointslices -l kubernetes.io/service-name=outpost-probe -o yaml
kubectl -n outpost exec outpost-scout-0 -- curl -sS --max-time 5 -o /dev/null -w '%{http_code}\n' http://outpost-scout:9898
kubectl -n outpost exec outpost-scout-0 -- curl -sS --max-time 5 -o /dev/null -w '%{http_code}\n' http://outpost-probe:9898
```

An EndpointSlice records the addresses and readiness of a Service's backends.
The UIDs should match your notes, while the revision name should change.
Look for `Synced` and `Ready` set to `True`, Service owner references naming
the matching XR UID, and ready EndpointSlice targets naming the matching
StatefulSet Pods. Each HTTP request should return status `200`.
The pinned workload image includes `curl`, so no extra client is needed.

**Check the watch terminal:** it shows `existing-request-updated`
and `services-reach-pods` passing once reconciliation completes.

## Step 5: Submit

When all four checks are green, press Ctrl-C to stop the watch and run the submit command once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-02/labs/lab-04
```

## If a check stays red

- **`tenant-request` fails.** Check the namespace, `team`, Composition reference
  and update policy. Read the XR conditions if its StatefulSet is not ready.
- **`composition-extended` fails.** Put the Service under the function input's
  resource list. Preserve the original two entries. Use the exact patch
  order and native field paths shown above.
- **`existing-request-updated` fails.** Wait for revision adoption and the new
  Service. Check `Automatic` and the active revision. Deleting the original
  objects breaks the identity requirement; a fresh lab start is needed to
  recover the recorded initial state.
- **`services-reach-pods` fails.** Compare each Service selector with the Pod
  labels. Inspect ready EndpointSlice targets and ports. Correct the
  Composition instead of creating or editing a Service by hand.
