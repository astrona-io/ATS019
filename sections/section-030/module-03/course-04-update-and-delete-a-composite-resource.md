# Update And Delete A Composite Resource

A request has a life after it is ready. The tenant changes it, and one day the tenant deletes it. The platform team must know what Crossplane does in both cases, because deletion is the one change that removes a running workload.

## Change the request and watch it flow down

Crossplane reconciles a composite resource all the time, not only when it is created. When the tenant changes the `spec`, Crossplane runs the Composition again and applies the new result to the composed `Object` resources. `provider-kubernetes` then updates the real objects. The change flows down the same path as the first request.

<!-- astrona:playground:renew -->

First read which values the XRD allows for `size`:

```sh
kubectl get xrd teamenvironments.platform.starfleet.io -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema.properties.spec.properties.size}{"\n"}'
```

The output shows the type of `size` and, if the XRD sets one, the list of allowed values. Choose a different allowed value. This example uses `medium`; replace it with your value if the list differs. Change the request with a merge patch:

```sh
kubectl -n outpost patch teamenvironment scout-env --type merge -p '{"spec":{"size":"medium"}}'
```

Then wait until the composite resource is `Ready` again and check what changed:

```sh
kubectl -n outpost wait teamenvironment/scout-env --for=condition=Ready --timeout=180s
crossplane resource trace teamenvironment scout-env -n outpost
```

The tenant changed one field of one object. The Composition decides which composed resources use that field. If the API server refuses the value, the XRD schema rejected it, and the existing objects stay as they were.

## Delete the composite resource

Deleting a composite resource also removes what it created. Crossplane sets an owner reference on every composed resource, with the composite resource as the owner. The Kubernetes garbage collector deletes a dependent when its owner goes. Then `provider-kubernetes` deletes the real object that each deleted `Object` created. The chain has two steps, and two components do the work.

Delete the request and watch the objects go:

```sh
kubectl -n outpost delete teamenvironment scout-env
kubectl -n outpost get objects.kubernetes.m.crossplane.io
kubectl -n outpost get deployment,service scout
```

The delete command returns when the composite resource is gone. The `Object` list and the Deployment and Service can take a short time to empty, because the garbage collector and `provider-kubernetes` work after the request is gone. Run the last two commands again until the `scout` Deployment and Service are gone. You should see `NotFound` for `scout` at the end.

A `Ready` composite resource that you delete this way leaves nothing behind. This is the behaviour a tenant wants from self-service: asking for the platform API again later gives a clean start.

## Orphan the composed resources

Sometimes the platform team wants to remove the request and keep the workload. Orphan deletion removes the owner reference from each dependent, and then deletes only the owner. Request a new `TeamEnvironment` with the file `teamenvironment-scout-env.yaml` (the same one used to request `scout-env` before), apply it, wait for `Ready`, and then delete it with orphan cascading:

```sh
kubectl apply -f teamenvironment-scout-env.yaml
kubectl -n outpost wait teamenvironment/scout-env --for=condition=Ready --timeout=180s
kubectl -n outpost delete teamenvironment scout-env --cascade=orphan
```

Check what is left:

```sh
kubectl -n outpost get objects.kubernetes.m.crossplane.io
kubectl -n outpost exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://scout:9898
```

You should see that the `Object` resources still exist and that `scout` still answers with `200`. No composite resource owns them now. Nothing updates them when the Composition changes, and nothing reports a `Ready` condition for the request.

Orphaned `Object` resources still delete their real objects when you delete them, because the provider keeps its default behaviour. Clean up by deleting the orphaned `Object` resources:

```sh
kubectl -n outpost delete objects.kubernetes.m.crossplane.io --all
```

## Choose between delete and orphan

Delete the composite resource when the tenant no longer needs the workload. That is the normal case, and it keeps the cluster clean. Orphan the composed resources only for a planned handover, for example when another team will take over the running workload. After an orphan delete, the platform team owns the cleanup.

You now know the whole life of a request: the tenant applies it, Crossplane and the provider create the objects, the conditions report the state, and deleting the request removes the objects through ownership. The module has followed one `TeamEnvironment` from the first `apply` to its last object. The tree and the conditions are the tools you use at each point.

## Common pitfalls

> [!WARNING]
> - **Orphaning to avoid a stuck deletion.** Orphan deletion keeps the workload and leaves it without a composite resource. Find why the deletion is stuck instead.
> - **Deleting the composed `Object` resources by hand.** Crossplane recreates them while the composite resource exists, and the tenant sees a flapping workload. Delete the composite resource.
> - **Believing the garbage collector removed the workload.** The garbage collector only deletes the `Object`. `provider-kubernetes` deletes the real Deployment and Service after that.

## Your mission: Delete A Composite Resource Without Losing Its Workload

You can now choose between deleting a composite resource and orphaning its composed resources. The mission asks you to remove a `TeamEnvironment` so that its `scout` workload still answers with `200`, and then to clean up the orphaned `Object` resources.

First pause the playground:

```sh
astrona stop ats-019-playground-030-03
```

Start the lab, then submit your work when you are done:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-03/labs/lab-03
astrona submit -c sections/section-030/module-03/labs/lab-03
```

When the lab is finished, remove it and start the playground again:

```sh
astrona destroy ats-019-lab-030-03-03
astrona start ats-019-playground-030-03
```
