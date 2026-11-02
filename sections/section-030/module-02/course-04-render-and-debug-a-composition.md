# Render And Debug A Composition

Applying a broken Composition to a live cluster changes real objects. A local preview avoids that risk. This part renders the Composition on your machine, then points a Composition at a function that does not exist and reads what Crossplane reports.

## Preview with crossplane composition render

The `crossplane composition render` command runs the pipeline on your machine. It takes an XR file, a Composition file and a file that lists the functions. It prints the resources the pipeline would create. It does not call the cluster API for the XR, so nothing in the cluster changes.

The command runs each function as a container, so it needs a local container runtime. It also pulls the function image, so it needs outbound internet.

The command needs a `Function` file. Save this as `functions.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Function
metadata:
  name: function-patch-and-transform
spec:
  package: xpkg.crossplane.io/crossplane-contrib/function-patch-and-transform:v0.11.0
```

Save this as `xr.yaml`. It is a request with a replica count that differs from the default:

```yaml
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: preview
  namespace: outpost
spec:
  team: drifter
  replicas: 3
```

Render it with the Composition file from the previous step:

```sh
crossplane composition render xr.yaml composition-teamenvironment.yaml functions.yaml
```

You should see YAML for the XR, followed by two `Object` resources. In the Deployment `Object`, `replicas` should be `3`, `namespace` should be `outpost`, and the pod template should carry the label `team: drifter`. Render is the quickest way to test a patch path: change the Composition, run the command, and read the result in seconds.

## Break the Composition on purpose

A Composition that names a missing function is a common mistake. Save a copy of the Composition under a new name, with the function name changed. Save this as `composition-teamenvironment-broken.yaml`:

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: teamenvironment-broken
spec:
  compositeTypeRef:
    apiVersion: platform.starfleet.io/v1alpha1
    kind: TeamEnvironment
  mode: Pipeline
  pipeline:
    - step: patch-and-transform
      functionRef:
        name: function-patch-and-transfrom
      input:
        apiVersion: pt.fn.crossplane.io/v1beta1
        kind: Resources
        resources: []
```

The name `function-patch-and-transfrom` has a typo. Crossplane accepts the Composition, because the API server only checks its shape. The fault shows up when an XR uses it. To make the XR use this Composition, set a Composition reference with a patch:

```sh
kubectl apply -f composition-teamenvironment-broken.yaml
kubectl -n outpost patch teamenvironment outpost-env --type=merge -p '{"spec":{"crossplane":{"compositionRef":{"name":"teamenvironment-broken"}}}}'
```

## Read the status

The XR shows what is wrong. Read its conditions:

```sh
kubectl -n outpost get teamenvironment outpost-env -o jsonpath='{range .status.conditions[*]}{.type}{"="}{.status}{" "}{.reason}{" "}{.message}{"\n"}{end}'
kubectl -n outpost describe teamenvironment outpost-env
```

You should see a `Synced` condition that is not `True`, and a message that names the function `function-patch-and-transfrom`. The `describe` output should list an event with the same message. Because Crossplane could not run the pipeline, it did not change the composed objects. The Deployment and Service from before stay in place.

Fix the fault in the Composition, not in the XR. Point the XR back at the working Composition and delete the broken one:

```sh
kubectl -n outpost patch teamenvironment outpost-env --type=merge -p '{"spec":{"crossplane":{"compositionRef":{"name":"teamenvironment"}}}}'
kubectl delete composition teamenvironment-broken
```

A few seconds later, `Synced` and `Ready` should be `True` again. Always read the XR conditions first, then the events, and only then the composed `Object` status. That order moves from the request toward the provider, and it shows which component stopped.

## What you can now do

You wrote an XRD and a Composition, patched values in both directions, and previewed the result without touching the cluster. You also read the status of a Composition that points at a missing function. A question remains for the platform team: how does a tenant know which of its requests are healthy across many namespaces?

## Your mission: Repair A Broken Composition

You can now preview a Composition and find a bad function reference from the XR status. The mission gives you a platform API whose Composition does not produce a workload, and asks you to find the fault and restore a request that answers with `200`.

Pause the playground:

```sh
astrona stop ats-019-playground-030-02
```

Run and submit the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-02/labs/lab-03
astrona submit -c sections/section-030/module-02/labs/lab-03
```

When you are done, remove the lab and resume the playground:

```sh
astrona destroy ats-019-lab-030-02-03
astrona start ats-019-playground-030-02
```

## Common pitfalls

> [!WARNING]
> - **Trusting the apply.** The API server accepts a Composition with a missing function. The fault appears only on an XR that uses it.
> - **Rendering without a container runtime.** `crossplane composition render` runs functions as containers.
> - **Editing the XR to fix a Composition fault.** Fix the Composition and let Crossplane reconcile.
> - **Treating render as a full test.** It shows the resources, not whether the provider can create them.
