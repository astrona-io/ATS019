# Overview: Define A Platform API With An XRD And Composition (Playground)

This playground is an empty platform. Crossplane, one provider and one composition function are installed and healthy, but no platform API exists yet. You write the CompositeResourceDefinition (XRD) and the Composition yourself. There is nothing to submit and no grading.

## What's in the box

The single-node `kind` cluster runs Kubernetes 1.35.8 and Crossplane 2.4.2. Crossplane pulls its packages from `xpkg.crossplane.io`, so the cluster needs outbound internet.

| Object | Where | What it does |
| --- | --- | --- |
| Crossplane 2.4.2 | `crossplane-system` | Runs the composite resource and package controllers |
| `Provider` `provider-kubernetes` 1.4.1 | cluster | Creates Kubernetes objects on behalf of Crossplane, using the ServiceAccount `provider-kubernetes` |
| `Function` `function-patch-and-transform` 0.11.0 | cluster | Runs the patches of a Composition pipeline |
| `ClusterProviderConfig` `in-cluster` | cluster | Tells the provider to manage the cluster it runs in, with its own ServiceAccount identity |
| `Role` `composed-workloads` and its `RoleBinding` | `outpost` | Lets the provider manage Deployments and Services in `outpost`, and nothing else |

The namespace `starfleet` belongs to the platform team. The namespace `outpost` belongs to a tenant team. A composite resource (XR) is one object of the type an XRD defines. In Crossplane 2.x, an XR is namespaced by default, so a request from `outpost` and the objects Crossplane creates for it all live in `outpost`.

No XRD, no Composition and no workload exist. The images for the `scout` workload (`ghcr.io/stefanprodan/podinfo:6.15.0`) are already preloaded.

## The Crossplane command line tool

The module uses two commands of the `crossplane` command line tool (CLI): `crossplane resource trace` and `crossplane composition render`. Version 2.4.1 of the CLI works with Crossplane 2.4.2. The CLI runs on your own machine, not in the cluster. Check that it is installed with `crossplane --version`.

The `render` command runs each function as a container, so it needs a container engine on your machine, and it pulls the function image from the internet.

## Practice tasks

- Write an XRD for a `TeamEnvironment` with a required `team`, a `size` that accepts `small`, `medium` or `large`, and a `replicas` field from 1 to 3. Wait for the `Established` condition. Then apply a request with `replicas: 9` and read the error.
- Write a Composition in `Pipeline` mode that creates the `scout` Deployment through a `provider-kubernetes` `Object`. Create a `TeamEnvironment` in `outpost` and wait for `Ready`. Follow it with `crossplane resource trace`.
- Add the `scout` Service and the patches that copy `metadata.namespace`, `spec.replicas` and `spec.team` into the composed objects. Change `spec.replicas` on the XR and watch the Deployment follow.
- Send a request to the Service from a `shuttle` pod and check that it returns `200`.
- Break the Composition on purpose: change the `functionRef` name by one letter, point an XR at it and read the `Synced` condition and the events.
- Run `crossplane composition render` with the Composition, an XR file and a `Function` file, and compare the output with what the cluster creates.
