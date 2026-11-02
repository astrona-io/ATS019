# From A CRD To An XRD

A tenant should be able to ask for a workload with a few fields: the owning team, a size and a number of replicas. The platform team must also be able to reject bad requests before anything is created. A CompositeResourceDefinition (XRD) gives them both.

## What an XRD adds to a CRD

An XRD is a Crossplane object that defines a new platform API. When you create it, Crossplane reads its schema and creates a real CustomResourceDefinition (CRD) in the cluster. An object of the new type is called a composite resource (XR). The API server validates an XR with the same OpenAPI v3 schema rules it uses for any custom resource.

The XRD also adds Crossplane fields that a plain CRD does not have. Crossplane writes `spec.crossplane` fields into each XR to select a Composition and to record the composed resources. It also adds standard status conditions.

In Crossplane 2.x, the XRD uses `apiextensions.crossplane.io/v2` and its `scope` is `Namespaced` by default. A namespaced XR lives in the tenant's namespace, and so do the objects Crossplane creates for it. Claims, a second object type that older versions used to make a namespaced request, exist only for `scope: LegacyCluster`. This module does not use claims.

## Write the XRD

Save this as `xrd-teamenvironment.yaml`. The XRD name must be the plural name plus the group.

<!-- astrona:playground:renew -->

```yaml
apiVersion: apiextensions.crossplane.io/v2
kind: CompositeResourceDefinition
metadata:
  name: teamenvironments.platform.starfleet.io
spec:
  scope: Namespaced
  group: platform.starfleet.io
  names:
    kind: TeamEnvironment
    plural: teamenvironments
  versions:
    - name: v1alpha1
      served: true
      referenceable: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                team:
                  type: string
                size:
                  type: string
                  enum: [small, medium, large]
                  default: small
                replicas:
                  type: integer
                  minimum: 1
                  maximum: 3
                  default: 1
                contact:
                  type: string
              required:
                - team
            status:
              type: object
              properties:
                availableReplicas:
                  type: integer
```

Apply it:

```sh
kubectl apply -f xrd-teamenvironment.yaml
```

The `spec` schema holds the four fields a tenant may set. `team` is required. `size` accepts only `small`, `medium` or `large`. `replicas` has a minimum and a maximum. `size` and `replicas` have defaults, and `contact` is optional. The `status` schema declares a field that a later part fills. `referenceable: true` marks the one version that a Composition may target.

## Check that Crossplane accepted it

Crossplane needs a few seconds to create the CRD. Wait for the `Established` condition, then list the XRD and the new resource type:

```sh
kubectl wait xrd teamenvironments.platform.starfleet.io --for=condition=Established --timeout=60s
kubectl get xrd teamenvironments.platform.starfleet.io
kubectl api-resources --api-group=platform.starfleet.io
```

You should see the `wait` command report the XRD as condition met, and `kubectl get xrd` show `ESTABLISHED True`. The `api-resources` list should show `teamenvironments`, namespaced, with kind `TeamEnvironment`. The `Established` condition has the reason `WatchingCompositeResource`, which means Crossplane created the CRD and now watches for XRs of this type.

## Prove the schema rejects bad input

The API server enforces the schema before Crossplane sees the object. Save this as `teamenvironment-invalid.yaml`:

```yaml
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: too-big
  namespace: outpost
spec:
  team: drifter
  replicas: 9
```

Apply it:

```sh
kubectl apply -f teamenvironment-invalid.yaml
```

You should see an error from the server that names `spec.replicas` and says the value must be less than or equal to 3. Nothing is stored, so no Composition could ever act on it. A schema is the first safety rule of a platform API.

## Common pitfalls

> [!WARNING]
> - **Wrong XRD name.** The name must be `<plural>.<group>`. Any other name is refused.
> - **Changing `group` or `names` later.** Crossplane does not allow it. Delete and recreate the XRD instead.
> - **Using claims by habit.** Claims exist only for `scope: LegacyCluster`. A namespaced XR is created directly.
> - **Applying an XR before `Established`.** The resource type does not exist yet, so the request fails.
