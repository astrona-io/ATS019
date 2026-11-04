# Extend A Native Composition

A platform application programming interface (API) can gain a new resource while existing requests keep running.
The `outpost-scout` workload needs a client Service as well as its StatefulSet.
A StatefulSet is a Kubernetes controller that gives Pods stable names. A Service selects Pods and provides network access to them. A Composition is a Crossplane object that defines the resources to create for a request. This
example adds a Service through the Composition, then compares object
identities to check that Crossplane updated the existing request in place.

## Consume the existing API

The existing `TeamEnvironment` CompositeResourceDefinition (XRD) defines a
namespaced platform API. A composite resource (XR) is one request of that
type. Its `spec.team` field is required. Here Crossplane 2.4.2 composes native
Kubernetes objects directly, so these resources have no provider `Object`
wrapper and need no provider. The function's patch paths start at each
native object's root.

Use the playground with the `TeamEnvironment` XRD already applied. Read its
schema before creating another request:

<!-- astrona:playground:renew -->

```sh
kubectl get xrd teamenvironments.platform.starfleet.io -o yaml
kubectl explain teamenvironment.spec
```

Look for `scope: Namespaced`, version `v1alpha1` and the required `team`
field. A tenant creates an XR; it does not need to create another XRD.

## Start with the native workload

A headless Service has `clusterIP: None`. It provides the network identity
used by the StatefulSet's `serviceName`. A separate client Service will
receive an allocated cluster IP address. Crossplane already has Service
permissions; the ClusterRole below grants StatefulSet permissions through
role aggregation, which combines labelled roles into Crossplane's role.

Save this as `composition-scout-stateful.yaml`. The file contains the
permission, the partial Composition and one request:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: starfleet-compose-statefulsets
  labels:
    rbac.crossplane.io/aggregate-to-crossplane: 'true'
rules:
  - apiGroups:
      - apps
    resources:
      - statefulsets
    verbs:
      - get
      - list
      - watch
      - create
      - update
      - patch
      - delete
---
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: scout-stateful
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
          - name: governing-service
            base:
              apiVersion: v1
              kind: Service
              metadata: {}
              spec:
                clusterIP: None
                selector: {}
                ports:
                  - port: 9898
                    targetPort: 9898
            patches:
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.name
                toFieldPath: metadata.name
                transforms:
                  - type: string
                    string:
                      type: Format
                      fmt: '%s-pods'
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.namespace
                toFieldPath: metadata.namespace
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.name
                toFieldPath: spec.selector.app
            readinessChecks:
              - type: MatchString
                fieldPath: spec.clusterIP
                matchString: None
          - name: statefulset
            base:
              apiVersion: apps/v1
              kind: StatefulSet
              metadata: {}
              spec:
                replicas: 1
                selector:
                  matchLabels: {}
                template:
                  metadata:
                    labels: {}
                  spec:
                    containers:
                      - name: scout
                        image: ghcr.io/stefanprodan/podinfo:6.15.0
                        ports:
                          - containerPort: 9898
                        readinessProbe:
                          httpGet:
                            path: /readyz
                            port: 9898
            patches:
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.name
                toFieldPath: metadata.name
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.namespace
                toFieldPath: metadata.namespace
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.name
                toFieldPath: spec.serviceName
                transforms:
                  - type: string
                    string:
                      type: Format
                      fmt: '%s-pods'
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.name
                toFieldPath: spec.selector.matchLabels.app
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.name
                toFieldPath: spec.template.metadata.labels.app
            readinessChecks:
              - type: MatchInteger
                fieldPath: status.readyReplicas
                matchInteger: 1
---
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: outpost-scout
  namespace: outpost
spec:
  team: scout
  crossplane:
    compositionRef:
      name: scout-stateful
    compositionUpdatePolicy: Automatic
```

Apply it:

```sh
kubectl apply -f composition-scout-stateful.yaml
```

The patches copy the XR name into the workload name and both Pod label
selectors. The string transform adds `-pods` for the governing Service name.
The fixed replica count is one; this example does not patch `spec.replicas`
from the request. Crossplane creates the StatefulSet and Services; the
StatefulSet controller creates the Pod.

Wait for readiness, then record the unique identifier (UID) of the XR and
StatefulSet and note the active Composition revision:

```sh
kubectl -n outpost wait teamenvironment/outpost-scout --for=condition=Ready --timeout=300s
kubectl -n outpost get teamenvironment outpost-scout -o jsonpath='{.metadata.uid}{"\n"}{.spec.crossplane.compositionRevisionRef.name}{"\n"}'
kubectl -n outpost get statefulset outpost-scout -o jsonpath='{.metadata.uid}{"\n"}'
```

The function's default readiness check expects a `Ready` condition. Native
StatefulSets and Services do not expose that condition, so the templates use
explicit `readinessChecks`. In `function-patch-and-transform` 0.11.0,
`MatchInteger` compares a field with an integer and `MatchString` compares it
with a string. The workload check requires one ready replica, while the
headless Service check matches the literal string `None`.

## Add the client Service

Append this entry to the Composition's
`spec.pipeline[0].input.resources` list, after `statefulset`. Keep the two
existing entries and the request unchanged. Save this as the updated
`composition-scout-stateful.yaml`:

```yaml
          - name: service
            base:
              apiVersion: v1
              kind: Service
              metadata: {}
              spec:
                type: ClusterIP
                selector: {}
                ports:
                  - port: 9898
                    targetPort: 9898
            patches:
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.name
                toFieldPath: metadata.name
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.namespace
                toFieldPath: metadata.namespace
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.name
                toFieldPath: spec.selector.app
            readinessChecks:
              - type: NonEmpty
                fieldPath: spec.clusterIP
```

Apply it:

```sh
kubectl apply -f composition-scout-stateful.yaml
```

The three patches set the Service name, namespace and selector from the XR.
The selector matches the StatefulSet's Pod template label. `NonEmpty` checks
for `spec.clusterIP` on the observed Service. Do not use
`status.atProvider.manifest.spec.clusterIP`: that path belongs to a provider
wrapper. Address allocation does not prove that a Service has ready backends;
check its EndpointSlices and send a request too. An EndpointSlice records the addresses and readiness of a Service's backends.

A Composition revision is an immutable snapshot of a Composition.
`spec.crossplane.compositionUpdatePolicy: Automatic` lets existing requests
adopt newer revisions. Crossplane runs the updated pipeline and adds the new
Service. A request with `Manual` update policy keeps its selected revision
until it is changed explicitly. Keep resource entry names stable so
Crossplane can identify the existing composed resources.

Read the identities again and check the new Service with a Hypertext Transfer Protocol (HTTP) request:

```sh
kubectl -n outpost get teamenvironment outpost-scout -o jsonpath='{.metadata.uid}{"\n"}{.spec.crossplane.compositionRevisionRef.name}{"\n"}'
kubectl -n outpost get statefulset outpost-scout -o jsonpath='{.metadata.uid}{"\n"}'
kubectl -n outpost get service outpost-scout -o yaml
kubectl -n outpost get endpointslices -l kubernetes.io/service-name=outpost-scout -o yaml
kubectl -n outpost exec outpost-scout-0 -- curl -sS --max-time 5 -o /dev/null -w '%{http_code}\n' http://outpost-scout:9898
```

Compare both UIDs with your earlier notes; they should stay unchanged while
the revision name changes. Look for an allocated Service address, an owner
reference to the XR, and a ready EndpointSlice target for `outpost-scout-0`.
The request should return HTTP status `200`. The pinned workload image
includes `curl`. These observations check different things: identity,
revision adoption, ownership, Pod selection and traffic.

An existing request can now gain a native Service through its Composition.
The function checks fields on the native resources, and the revision policy
decides which requests adopt the change. Stable UIDs prove continuity;
ready endpoints and a successful request prove that the new Service works.

## Common pitfalls

> [!WARNING]
> - **Using `Condition` as a check type.** The valid condition check is `MatchCondition`. The checks used here are `MatchInteger`, `MatchString` and `NonEmpty`.
> - **Leaving the default readiness check.** These native objects have no `Ready` condition. Check the fields they actually expose.
> - **Changing a resource entry name.** Crossplane uses it to identify a composed resource. Preserve the existing names when extending the list.
> - **Assuming every request upgrades.** A request using `Manual` update policy does not automatically adopt the new revision.
> - **Treating an address as proof of traffic.** A Service can have an address while selecting no ready Pods. Check EndpointSlices and send a request.
