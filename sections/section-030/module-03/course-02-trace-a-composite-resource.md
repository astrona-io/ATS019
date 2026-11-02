# Trace A Composite Resource

One `TeamEnvironment` is ready, but you do not yet know what it created. When a platform request fails, the first job is to find every object that belongs to it. Crossplane records those links on the composite resource, so you can read them instead of searching by name.

## Read the references on the composite resource

Crossplane keeps the list of composed resources in the composite resource itself. In Crossplane 2.x, the fields Crossplane manages sit under `spec.crossplane`. The field `spec.crossplane.resourceRefs` lists each composed resource with its `apiVersion`, `kind` and `name`. The field `spec.crossplane.compositionRef` names the Composition that Crossplane selected.

<!-- astrona:playground:renew -->

Print the Composition and the references for the `scout-env` request:

```sh
kubectl -n outpost get teamenvironment scout-env -o jsonpath='{.spec.crossplane.compositionRef.name}{"\n"}'
kubectl -n outpost get teamenvironment scout-env -o jsonpath='{range .spec.crossplane.resourceRefs[*]}{.kind}{"  "}{.name}{"\n"}{end}'
```

The first command prints the name of the working Composition. The second prints one line for each composed resource. Their kind is `Object`, the managed resource that `provider-kubernetes` controls. Crossplane writes `resourceRefs`, so you never edit it.

The tenant did not choose the Composition. Crossplane selected one, because the XRD or the cluster sets a default. A tenant who is allowed to can choose another Composition by name in `spec.crossplane.compositionRef.name`.

## Follow a composed resource to the real object

A composed `Object` is not the Deployment. It is a managed resource whose `spec.forProvider.manifest` holds the Deployment manifest. `provider-kubernetes` reads that manifest and creates the real Deployment in the cluster. This gives the platform two layers to check: the `Object` and the object it created.

List the managed resources first. A namespaced composite resource creates namespaced `Object` resources, in the API group `kubernetes.m.crossplane.io`:

```sh
kubectl -n outpost get objects.kubernetes.m.crossplane.io
```

If your `kubectl` says the resource does not exist, list the types the provider installed with `kubectl api-resources | grep kubernetes` and use the name it shows.

Each `Object` has its own `Synced` and `Ready` conditions. `Synced` means `provider-kubernetes` applied the manifest. `Ready` means the Deployment or Service it applied is ready. The composite resource becomes `Ready` only when every one of its `Object` resources is `Ready`.

## Trace the whole tree with one command

Following references by hand gets slow when a Composition creates many objects. The `crossplane resource trace` command reads the same references and prints the tree. Its arguments are the kind and the name, and a namespaced composite resource also needs the namespace:

```sh
crossplane resource trace teamenvironment scout-env -n outpost
```

You should see a tree. The root is the `TeamEnvironment` `scout-env`. Under it you should see one `Object` for each composed resource. Each row shows the object, its `Synced` and `Ready` state and a short status.

The tree is built from `resourceRefs`, so it shows exactly what you listed above, in one view. A row with `False` or `Unknown` in a column marks the place to look first. Run the command with `-o wide` to show more columns, such as the message of a failing condition:

```sh
crossplane resource trace teamenvironment scout-env -n outpost -o wide
```

The command is marked `[BETA]` in `crossplane --help`, and an older version was called `crossplane beta trace`. The output columns can change between CLI versions, so read the column headers instead of counting columns.

## Check the objects the Object created

The trace stops at the `Object`. The last step is to confirm that the real objects exist and that Crossplane owns them. Print the owner references of the `scout` Deployment:

```sh
kubectl -n outpost get deployment scout -o jsonpath='{.metadata.ownerReferences}{"\n"}'
```

You should see an empty line. `provider-kubernetes` applies the manifest, so the Deployment has no owner reference to the composite resource. The link goes one step at a time: the `TeamEnvironment` owns the composed `Object`, and the `Object` creates the Deployment. This matters for deletion, because Kubernetes follows owner references only one step at a time.

You now have three views of the same request: the references on the composite resource, the `Object` resources behind them and the tree from `crossplane resource trace`. The tree is the fastest of the three. The open question is what to do when one row of that tree is not ready.

## Common pitfalls

> [!WARNING]
> - **Using `crossplane resource trace` without a namespace.** A namespaced composite resource needs `-n outpost`. Without it the command looks in the wrong place.
> - **Editing `resourceRefs`.** Crossplane owns that list. A manual change is overwritten.
> - **Stopping the trace at the `Object`.** An `Object` can be `Synced` while the real Deployment is not ready. Check both layers.
