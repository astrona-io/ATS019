# Compose Resources With A Pipeline

The XRD defines the request, but nothing yet turns a `TeamEnvironment` into running pods. A Composition fills that gap. This part writes a Composition that creates the `scout` Deployment, and it shows which component does each step.

## How a Composition works

A Composition is a Crossplane object that says what to create for each composite resource (XR) of one type. In Crossplane 2.x, a Composition always uses `mode: Pipeline`. A pipeline is an ordered list of steps. Each step calls a composition function, which is a small program that receives the XR and returns the resources Crossplane should create. The older mode with a plain `resources:` list no longer exists.

Crossplane itself does not create the Deployment. It sends the XR to the function, reads the desired resources the function returns, and creates them. The function used here is `function-patch-and-transform`, which reads a list of base resources and a list of patches from its `input`.

The resources the function returns are not Deployments directly. In this playground they are `Object` resources from `provider-kubernetes`. An `Object` is a managed resource: a Kubernetes object that a provider controls. It wraps any Kubernetes manifest in `spec.forProvider.manifest`, and the provider creates that manifest in the cluster. This is the offline pattern. With a cloud provider, the wrapped thing would be a bucket or a database, and the Composition would look the same.

Check that the function is ready before you use it:

<!-- astrona:playground:renew -->

```sh
kubectl get functions
```

You should see `function-patch-and-transform` with `INSTALLED True` and `HEALTHY True`.

## Write the Composition

Save this as `composition-teamenvironment.yaml`. The `compositeTypeRef` field says which XR type this Composition serves. The `functionRef` name must equal the name of the installed Function.

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: teamenvironment
spec:
  compositeTypeRef:
    apiVersion: platform.starfleet.io/v1alpha1
    kind: TeamEnvironment
  mode: Pipeline
  pipeline:
    - step: patch-and-transform
      functionRef:
        name: function-patch-and-transform
      input:
        apiVersion: pt.fn.crossplane.io/v1beta1
        kind: Resources
        resources:
          - name: deployment
            base:
              apiVersion: kubernetes.m.crossplane.io/v1alpha1
              kind: Object
              spec:
                providerConfigRef:
                  kind: ClusterProviderConfig
                  name: in-cluster
                forProvider:
                  manifest:
                    apiVersion: apps/v1
                    kind: Deployment
                    metadata:
                      name: scout
                    spec:
                      replicas: 1
                      selector:
                        matchLabels:
                          app: scout
                      template:
                        metadata:
                          labels:
                            app: scout
                        spec:
                          containers:
                            - name: scout
                              image: ghcr.io/stefanprodan/podinfo:6.15.0
                              ports:
                                - containerPort: 9898
```

Apply it:

```sh
kubectl apply -f composition-teamenvironment.yaml
```

The `base` of the resource is a full `Object`. The `providerConfigRef` tells the provider which connection to use; `in-cluster` points back at this cluster. This Composition has no patches yet, so every `TeamEnvironment` gets the same Deployment.

## Create a request

Save this as `teamenvironment-probe.yaml`. It sets only the required `team` field, so the XRD defaults apply to the others.

```yaml
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: outpost-env
  namespace: outpost
spec:
  team: drifter
```

Apply it and watch it become ready:

```sh
kubectl apply -f teamenvironment-probe.yaml
kubectl -n outpost wait teamenvironment outpost-env --for=condition=Ready --timeout=120s
```

The `Ready` condition becomes `True` when every composed resource is ready. The XR also carries a `Synced` condition, which is `True` when Crossplane could run the pipeline and apply its result without an error.

## Trace the XR to what it created

The `crossplane resource trace` command prints an XR with all the resources it composed.

```sh
crossplane resource trace teamenvironment outpost-env -n outpost
```

You should see the `TeamEnvironment` at the top and one `Object` below it, both with `SYNCED True`. Then check that the provider created the workload:

```sh
kubectl -n outpost get deployment scout
```

The Deployment `scout` should exist in `outpost`. The chain is now clear. The tenant created the XR, Crossplane called the function, the function returned an `Object`, and `provider-kubernetes` created the Deployment.

One value is still wrong. The Deployment ignores the `replicas` and `team` fields of the request. The next question is how to copy those values from the XR into the composed resource.

## Common pitfalls

> [!WARNING]
> - **A `functionRef` name that does not match.** The name must be the name of the installed Function, not the package name.
> - **Using the old `resources:` mode.** Crossplane 2.x supports only `mode: Pipeline`.
> - **Expecting a Deployment from the XR directly.** Crossplane composes `Object` resources, and the provider creates the Deployment.
> - **A wrong `compositeTypeRef`.** If the group, version or kind differs from the XRD, the XR finds no Composition.
