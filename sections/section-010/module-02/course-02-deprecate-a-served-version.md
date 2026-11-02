# Deprecate A Served Version

An old version sometimes needs to stay available after a new version is ready. Existing clients may need time to change. Kubernetes lets a CustomResourceDefinition mark a served version as deprecated, so the API server still accepts it but warns clients that use it.

## Add the deprecation flag

A **deprecated version** is a served CRD version that still works but returns a warning header. `kubectl` prints that warning on standard error. This is useful when a platform team wants users to move to a stable version before the old one is removed.

The file below is the two-version CRD with two new fields on `v1alpha1`: `deprecated: true` turns the warning on, and `deprecationWarning` sets its text.

<!-- astrona:playground:renew -->

Save this as `crd-teamenvironment-deprecated.yaml`:

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
      served: true
      storage: false
      deprecated: true
      deprecationWarning: "platform.starfleet.io/v1alpha1 TeamEnvironment is deprecated; use platform.starfleet.io/v1"
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
    - name: v1
      served: true
      storage: true
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
kubectl apply -f crd-teamenvironment-deprecated.yaml
```

You should see:

```text
customresourcedefinition.apiextensions.k8s.io/teamenvironments.platform.starfleet.io configured
```

## Read the warning

Ask for the object through the deprecated version:

```sh
kubectl -n outpost get teamenvironments.v1alpha1.platform.starfleet.io alpha \
  -o jsonpath='{.apiVersion}{"\n"}'
```

You should see:

```text
Warning: platform.starfleet.io/v1alpha1 TeamEnvironment is deprecated; use platform.starfleet.io/v1
platform.starfleet.io/v1alpha1
```

The request succeeds. The warning tells the user that the version is deprecated, but it does not block the read.

Now ask for the same object through `v1`:

```sh
kubectl -n outpost get teamenvironments.v1.platform.starfleet.io alpha \
  -o jsonpath='{.apiVersion}{"\n"}'
```

You should see:

```text
platform.starfleet.io/v1
```

There is no warning because `v1` is not deprecated.

## Stop serving a version

Deprecation is different from removal. If you set `served: false` for `v1alpha1`, the API server stops accepting that version. A client that still uses it gets an error.

The old version stays in the list with `served: false`. Its schema can be short, because no client can use it any more, but every listed version still needs a schema.

Save this as `crd-teamenvironment-v1-only.yaml`:

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

Apply it, then try the old version:

```sh
kubectl apply -f crd-teamenvironment-v1-only.yaml
kubectl -n outpost get teamenvironments.v1alpha1.platform.starfleet.io alpha
```

You should see:

```text
customresourcedefinition.apiextensions.k8s.io/teamenvironments.platform.starfleet.io configured
Error from server (NotFound): the server could not find the requested resource (get teamenvironments.platform.starfleet.io alpha)
```

The API server no longer has a `v1alpha1` endpoint for `teamenvironments`, so it answers `NotFound`. The object `alpha` still exists; only the version is gone. A `kubectl` with no cached discovery data stops even earlier and prints `error: the server doesn't have a resource type "teamenvironments"`. The `v1` endpoint still works:

```sh
kubectl -n outpost get teamenvironments.v1.platform.starfleet.io alpha \
  -o jsonpath='{.apiVersion}{"\n"}'
```

You should see:

```text
platform.starfleet.io/v1
```

For the rest of the module, use the `v1` version only. You have now seen the difference between a deprecated version, which warns and still works, and an unserved version, which clients can no longer use. The open question is how to split user writes to `spec` from controller writes to `status`.

## Common pitfalls

> [!WARNING]
> - **Treating a warning as a failure.** A deprecated served version still works; it only tells clients to move.
> - **Removing a version before clients stop using it.** `served: false` breaks requests that still name that version.
> - **Deleting the schema for an unserved version.** The CRD still needs a schema for every listed version. Without one, the API server refuses the CRD with `spec.versions[0].schema.openAPIV3Schema: Required value`.
> - **Forgetting that `kubectl` prints warnings on standard error.** A script that captures only standard output may miss the deprecation warning.
