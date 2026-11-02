# Patch Values In And Out

The first Composition creates the same Deployment for every request. A real platform API must pass the tenant's choices through. A patch copies a value from one object to another. This part sends the XR values into the Deployment, adds a Service, and writes a result back to the XR status.

## Patch from the XR into a composed resource

`function-patch-and-transform` supports several patch types. Two cover most work. `FromCompositeFieldPath` copies a field of the XR into the composed resource. `ToCompositeFieldPath` copies a field of the composed resource back into the XR. Each patch names a `fromFieldPath` and a `toFieldPath`.

The Deployment needs three values. The replica count comes from `spec.replicas`, and a `team` label on the pods comes from `spec.team`. The image stays fixed in the Composition. The namespace comes from `metadata.namespace`, so the Deployment lands in the namespace of the tenant's XR. Without that patch, the provider would create the Deployment in the default namespace.

## Write the full Composition

The new file adds the Service as a second resource. It also adds one `ToCompositeFieldPath` patch that reads the number of available replicas from the Deployment and writes it into the XR `status`. Save this as `composition-teamenvironment.yaml`, which replaces the earlier file of the same name:

<!-- astrona:playground:renew -->

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
            patches:
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.namespace
                toFieldPath: spec.forProvider.manifest.metadata.namespace
              - type: FromCompositeFieldPath
                fromFieldPath: spec.replicas
                toFieldPath: spec.forProvider.manifest.spec.replicas
              - type: FromCompositeFieldPath
                fromFieldPath: spec.team
                toFieldPath: spec.forProvider.manifest.spec.template.metadata.labels.team
              - type: ToCompositeFieldPath
                fromFieldPath: status.atProvider.manifest.status.availableReplicas
                toFieldPath: status.availableReplicas
          - name: service
            base:
              apiVersion: kubernetes.m.crossplane.io/v1alpha1
              kind: Object
              spec:
                providerConfigRef:
                  kind: ClusterProviderConfig
                  name: in-cluster
                forProvider:
                  manifest:
                    apiVersion: v1
                    kind: Service
                    metadata:
                      name: scout
                    spec:
                      selector:
                        app: scout
                      ports:
                        - port: 9898
                          targetPort: 9898
            patches:
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.namespace
                toFieldPath: spec.forProvider.manifest.metadata.namespace
```

Apply it:

```sh
kubectl apply -f composition-teamenvironment.yaml
```

Crossplane runs the pipeline again for every existing XR when the Composition changes. The `base` of each resource still holds the default values. The patches overwrite only the fields they name.

## Change the request and watch the result

Change the replica count of the existing XR with a patch, then read the Deployment:

```sh
kubectl -n outpost patch teamenvironment outpost-env --type=merge -p '{"spec":{"replicas":2}}'
kubectl -n outpost get deployment scout -o jsonpath='{.spec.replicas}{"\n"}'
```

You should see `2` after a few seconds. The `FromCompositeFieldPath` patch carried the new value. Crossplane did the work: it ran the pipeline, the function returned a changed `Object`, and the provider updated the Deployment.

Now read the status that flows the other way:

```sh
kubectl -n outpost get teamenvironment outpost-env -o jsonpath='{.status.availableReplicas}{"\n"}'
```

When both pods are available, you should see `2`. The value travelled from the Deployment status, through the `Object` status at `status.atProvider.manifest`, into the XR. The XRD schema declared `status.availableReplicas`, so the API server keeps the field. A status field that the schema does not declare would be pruned.

## Prove the Service answers

The last check is behaviour. The `shuttle` client pod sends a request to the Service that the Composition created. Save this as `deployment-shuttle.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shuttle
  namespace: outpost
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shuttle
  template:
    metadata:
      labels:
        app: shuttle
    spec:
      containers:
        - name: shuttle
          image: curlimages/curl
          command: ["sleep", "3600"]
```

Apply it and send a request:

```sh
kubectl apply -f deployment-shuttle.yaml
kubectl -n outpost rollout status deploy/shuttle
kubectl -n outpost exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://scout:9898
```

You should see `200`. One request now travels from a pod, through a Service, to a Deployment, and every object was created from a single `TeamEnvironment`. Both composed objects use the fixed name `scout`, so this simple Composition supports one `TeamEnvironment` per namespace.

## Your mission: Patch A Composition To Honour Tenant Requests

You can now copy values into composed resources, write values back to status, and prove the result with a request. The mission gives you a Composition that ignores one tenant field and asks you to patch it so that the workload follows the request.

Pause the playground:

```sh
astrona stop ats-019-playground-030-02
```

Run and submit the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-02/labs/lab-02
astrona submit -c sections/section-030/module-02/labs/lab-02
```

When you are done, remove the lab and resume the playground:

```sh
astrona destroy ats-019-lab-030-02-02
astrona start ats-019-playground-030-02
```

## Common pitfalls

> [!WARNING]
> - **Patching a path that does not exist.** The function reports an error for the path, and the pipeline step fails. Check the `Object` manifest layout.
> - **Forgetting the namespace patch.** The provider creates the composed object in the wrong namespace.
> - **Undeclared status fields.** A `ToCompositeFieldPath` patch to a field missing from the XRD schema is pruned and never shows.
> - **Editing a composed object by hand.** The provider and Crossplane reset it. Change the XR instead.
