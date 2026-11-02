# Scale A Custom Resource

Kubernetes has one standard way to resize workloads: the scale subresource. `kubectl scale` uses it for Deployments, StatefulSets and any custom resource that defines the same endpoint. This part adds `/scale` to `TeamEnvironment`, points it at `spec.replicas` and `status.readyReplicas`, and then uses `kubectl scale` on the custom resource.

## Enable the scale endpoint

The `scale` subresource returns an `autoscaling/v1` `Scale` object. For a CRD, the API server needs paths that connect that standard object to fields in the custom resource. `specReplicasPath` points at the desired replica count, and `statusReplicasPath` points at the observed ready count.

<!-- astrona:playground:renew -->

Save this as `crd-teamenvironment-scale.yaml`:

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: teamenvironments.platform.starfleet.io
spec:
  group: platform.starfleet.io
  scope: Namespaced
  names:
    kind: TeamEnvironment
    plural: teamenvironments
    singular: teamenvironment
    shortNames:
      - teamenv
  conversion:
    strategy: None
  versions:
    - name: v1alpha1
      served: false
      storage: false
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              x-kubernetes-preserve-unknown-fields: true
    - name: v1
      served: true
      storage: true
      subresources:
        status: {}
        scale:
          specReplicasPath: .spec.replicas
          statusReplicasPath: .status.readyReplicas
      additionalPrinterColumns:
        - name: Size
          type: string
          jsonPath: .spec.size
        - name: Replicas
          type: integer
          jsonPath: .spec.replicas
        - name: Ready
          type: integer
          jsonPath: .status.readyReplicas
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              required:
                - team
                - size
              properties:
                team:
                  type: string
                size:
                  type: string
                  enum:
                    - small
                    - medium
                    - large
                replicas:
                  type: integer
                  minimum: 0
                  maximum: 5
                  default: 1
            status:
              type: object
              properties:
                readyReplicas:
                  type: integer
                phase:
                  type: string
```

Apply it:

```sh
kubectl apply -f crd-teamenvironment-scale.yaml
```

You should see:

```text
customresourcedefinition.apiextensions.k8s.io/teamenvironments.platform.starfleet.io configured
```

## Read the Scale object

The raw scale endpoint shows the standard object that `kubectl scale` uses:

```sh
kubectl -n outpost get --raw \
  /apis/platform.starfleet.io/v1/namespaces/outpost/teamenvironments/alpha/scale
```

You should see:

```text
{"kind":"Scale","apiVersion":"autoscaling/v1","metadata":{"name":"alpha","namespace":"outpost","uid":"31c30cc6-5e15-4371-9ce1-56dc6c472b59","resourceVersion":"599","creationTimestamp":"2026-10-10T17:04:50Z"},"spec":{"replicas":2},"status":{"replicas":2}}
```

Your `uid`, `resourceVersion` and `creationTimestamp` differ. The important fields are `spec.replicas: 2`, read from `.spec.replicas`, and `status.replicas: 2`, read from `.status.readyReplicas`. There is no `selector` field, because the CRD sets no `labelSelectorPath`. The HorizontalPodAutoscaler needs that path; `kubectl scale` does not.

Now read the scale endpoint of `beta`, which has no status yet:

```sh
kubectl -n outpost get --raw \
  /apis/platform.starfleet.io/v1/namespaces/outpost/teamenvironments/beta/scale
```

You should see:

```text
{"kind":"Scale","apiVersion":"autoscaling/v1","metadata":{"name":"beta","namespace":"outpost","uid":"c665a8ba-b386-43b5-b34a-ac680a3b2630","resourceVersion":"478","creationTimestamp":"2026-10-10T17:04:50Z"},"spec":{"replicas":3},"status":{"replicas":0}}
```

`status.readyReplicas` is missing on `beta`, so the scale endpoint returns `status.replicas: 0`. That value does not mean anything was scaled down. It only means the status path is empty.

## Scale the custom resource

Use the same command style you would use for a Deployment:

```sh
kubectl -n outpost scale teamenvironment alpha --replicas=4
kubectl -n outpost get teamenvironment alpha \
  -o jsonpath='{.spec.replicas}{" ready="}{.status.readyReplicas}{"\n"}'
```

You should see:

```text
teamenvironment.platform.starfleet.io/alpha scaled
4 ready=2
```

The command changed `spec.replicas` through the scale endpoint. It did not change status. A controller would now observe that desired replicas are 4, create or remove whatever backing objects it controls, then write `status.readyReplicas`.

Act like that controller by patching status:

```sh
kubectl -n outpost patch teamenvironment alpha \
  --subresource=status \
  --type merge \
  -p '{"status":{"readyReplicas":4,"phase":"Ready"}}'
kubectl -n outpost get teamenv alpha
```

You should see:

```text
teamenvironment.platform.starfleet.io/alpha patched
NAME    SIZE    REPLICAS   READY
alpha   small   4          4
```

Now the desired count and the observed count match. The scale endpoint also runs the CRD schema. Ask for more replicas than `maximum: 5` allows:

```sh
kubectl -n outpost scale teamenvironment alpha --replicas=9
```

You should see:

```text
The TeamEnvironment "alpha" is invalid: spec.replicas: Invalid value: 9: spec.replicas in body should be less than or equal to 5
```

The API server refused the change, so `spec.replicas` stays `4`. The scale subresource did not create any pods, because a CRD is only an API type. It gave standard Kubernetes tools a way to read and write the replica count.

You can now publish a custom resource with versioning, a deprecated old version, a separate status endpoint and a standard scale endpoint. Those features make the API safer for clients and easier for controllers to use.

## Common pitfalls

> [!WARNING]
> - **Pointing `specReplicasPath` at a field that is not an integer.** The scale endpoint needs a numeric desired replica field.
> - **Expecting `kubectl scale` to update status.** It writes desired replicas. A controller writes observed replicas.
> - **Forgetting to enable `status` before relying on `statusReplicasPath`.** The scale endpoint can read status, but a controller still needs a safe way to write it.
> - **Thinking `/scale` creates pods.** It only changes the custom resource. A controller must act on the new desired state.
