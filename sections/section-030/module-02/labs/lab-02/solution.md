# Solution Walkthrough

You edit one object, the cluster-wide Composition `teamenvironment`, on the terminal where you started the lab. The request `outpost-env` stays as it is. Crossplane applies your change to it by itself.

| Goal | Where it lives | Command or file |
| --- | --- | --- |
| Copy a request value into a composed object | `FromCompositeFieldPath` patch | `fromFieldPath: spec.replicas` |
| Copy an observed value into the request | `ToCompositeFieldPath` patch | `fromFieldPath: status.atProvider.manifest.status.availableReplicas` |
| Allow the field to be stored | `status` schema of the XRD | `availableReplicas`, already declared |
| Apply the change | Composition `teamenvironment` | `kubectl apply -f composition-teamenvironment.yaml` |

## The feedback loop

Grading runs from the terminal on your machine, the same terminal where you typed `astrona run`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-02/labs/lab-02
```

Run it now and after every step. It runs four checks.

| Check | Turns green when |
| --- | --- |
| `composition-integrity` | `outpost-env` is the original request, uses `teamenvironment` and owns two composed Objects. This check passes from the start |
| `replicas-follow-request` | The Deployment follows `spec.replicas` of the request |
| `status-written-back` | `status.availableReplicas` shows the available replicas |
| `service-answers` | `shuttle` gets `200` and the pods carry `team: drifter`. This check passes from the start if the provider has created the workload |

The grader sets the request to 3 replicas and back to 2 during `replicas-follow-request`. This takes up to a few minutes.

## Step 1: Look at the starting state

Read the request, the Deployment and the Composition:

```sh
kubectl -n outpost get teamenvironment outpost-env -o jsonpath='{.spec.replicas}{"\n"}'
kubectl -n outpost get deployment scout -o jsonpath='{.spec.replicas}{"\n"}'
kubectl get composition teamenvironment -o yaml
```

The request asks for 2 replicas, but the Deployment has 1. In the Composition, the `deployment` resource has patches for the namespace and the `team` label, and none for `spec.replicas`. The base value `replicas: 1` is the only source. No check turns green in this step.

## Step 2: Add the replicas patch

The Composition must copy `spec.replicas` of the request into the manifest wrapped by the `Object`. Save the Composition below as `composition-teamenvironment.yaml`. It is the start file with two new patches in the `deployment` resource, a `FromCompositeFieldPath` patch for `spec.replicas` and a `ToCompositeFieldPath` patch for the status. You add both now, because they belong to one edit:

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

The new patches work like this:

- `fromFieldPath: spec.replicas` reads the field of the request. `toFieldPath` is the field inside the manifest that the `Object` wraps.
- The `ToCompositeFieldPath` patch goes the other way. It reads the observed Deployment, which `provider-kubernetes` reports under `status.atProvider.manifest`, and writes the number into `status.availableReplicas` of the request.

Apply it:

```sh
kubectl apply -f composition-teamenvironment.yaml
```

Crossplane runs the pipeline again for `outpost-env`. Read the Deployment after a few seconds:

```sh
kubectl -n outpost get deployment scout -o jsonpath='{.spec.replicas}{"\n"}'
```

The value is now `2`. Run the check. `replicas-follow-request` turns green.

## Step 3: Check the status field

The provider reads the Deployment again at a fixed interval, so the status needs a short time to arrive. Read it:

```sh
kubectl -n outpost get teamenvironment outpost-env -o jsonpath='{.status.availableReplicas}{"\n"}'
```

When both pods are available, the value is `2`. If the field is empty, wait half a minute and run the command again. Run the check. `status-written-back` turns green.

## Step 4: Prove the workload

Send a request from `shuttle` to the Service:

```sh
kubectl -n outpost exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://scout:9898
```

The output is `200`. Run the check. `service-answers` is green.

## Step 5: Submit

When all four checks are green, submit:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-02/labs/lab-02
```

## If a check stays red

- **`replicas-follow-request` fails and the Deployment stays at 1.** The patch is missing or has a wrong path. The `toFieldPath` must start with `spec.forProvider.manifest`, because the Deployment is wrapped inside the `Object`.
- **`replicas-follow-request` fails after you set `replicas: 2` in the base.** A fixed number follows no request. The grader changes the request to 3 and the Deployment does not follow.
- **`replicas-follow-request` fails after you edited the Deployment by hand.** The provider resets the Deployment to the manifest in the `Object`. Change the Composition.
- **`status-written-back` fails with an empty status.** Check the `fromFieldPath` of the `ToCompositeFieldPath` patch. It must be `status.atProvider.manifest.status.availableReplicas`. Describe the request and read the events for patch errors.
- **`composition-integrity` fails.** You deleted and created `outpost-env` again, or you pointed it at another Composition. A deleted request cannot get its identity back. Start over with `astrona reset`, and edit `teamenvironment` only.
