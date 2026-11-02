# Overview: Provision And Trace A Composite Resource (Playground)

This playground gives you a working Crossplane platform API to use, trace, break and delete. A composite resource (XR) is one object of the type that a CompositeResourceDefinition (XRD) defines. Here the type is `TeamEnvironment`. There is nothing to submit and no grading.

## What's in the box

The single-node `kind` cluster runs Kubernetes 1.35.8 and Crossplane 2.4.2 in the namespace `crossplane-system`. The cluster needs outbound internet access, because Crossplane pulls its packages from `xpkg.crossplane.io`.

| Item | What it is |
| --- | --- |
| `provider-kubernetes` 1.4.1 | The provider that creates Kubernetes objects for Crossplane. Its service account is `provider-kubernetes` in `crossplane-system` |
| `ClusterProviderConfig` `in-cluster` | Tells the provider to use its own service account token, so it manages this cluster |
| Role `provider-kubernetes-workloads` | Lets the provider manage Deployments, Services and ConfigMaps in `outpost` only |
| `function-patch-and-transform` 0.11.0 | The composition function that the Compositions call |
| XRD `teamenvironments.platform.starfleet.io` | The platform API. A `TeamEnvironment` is namespaced. `spec.team` is required, `size` is `small`, `medium` or `large` (default `small`), `replicas` is 1 to 3 (default 1), `contact` is optional |
| Composition `teamenvironment` | The working Composition and the default for the XRD. It creates the `scout` Deployment and Service in the namespace of the request |
| Composition `teamenvironment-with-cache` | Broken on purpose. A request that selects it never becomes ready |
| Deployment `shuttle` in `outpost` | A `curlimages/curl` pod. Send requests from it with `kubectl exec` |

No `TeamEnvironment` exists yet. You create the first one yourself. The namespaces `starfleet` and `outpost` exist, and `outpost` is the tenant namespace.

The `crossplane` command line tool, version 2.4.1, is saved in the folder `bin` of the shell's `/workspace` folder. It is released separately from Crossplane. Its commands `crossplane resource trace` and `crossplane composition render` are marked `[BETA]` in `--help`. If the shell does not find it, run `export PATH=$PATH:/workspace/bin` first.

## Practice tasks

- Request a `TeamEnvironment` in `outpost` with `replicas: 2`. Wait for `Ready`, then check that `scout` answers with `200` when `shuttle` sends a request to `http://scout:9898`.
- Print `spec.crossplane.compositionRef` and `spec.crossplane.resourceRefs` of the request. Then run `crossplane resource trace` on it and match each row to a field you printed.
- Request a second `TeamEnvironment` that selects `teamenvironment-with-cache` with `spec.crossplane.compositionRef.name`. Read its conditions, then find the function that is missing and the patch path that is misspelled.
- Change `spec.size` of a ready request and watch the conditions. Try a value that the XRD does not allow.
- Delete a request normally and watch the `Object` resources, the Deployment and the Service go. Request it again and delete it with `--cascade=orphan`. Check which objects remain, and what the remaining `Object` resources do when you delete them.
