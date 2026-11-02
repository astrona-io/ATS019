# Solution Walkthrough

You repair one object, the cluster-wide Composition `teamenvironment`, on the terminal where you started the lab. There are two faults in it. The request `outpost-env` stays as it is. Crossplane applies your repair to it by itself.

| Goal | Where to look | Command |
| --- | --- | --- |
| Find why nothing is created | Conditions and events of the request | `kubectl -n outpost describe teamenvironment outpost-env` |
| See what is installed | Functions | `kubectl get functions` |
| See what Crossplane composed | Resource tree of the request | `crossplane resource trace teamenvironment outpost-env -n outpost` |
| Find why the Service has no pods | Service and endpoints | `kubectl -n outpost get service,endpointslices` |
| Repair | Composition `teamenvironment` | `kubectl apply -f composition-teamenvironment.yaml` |

## The feedback loop

Grading runs from the terminal on your machine, the same terminal where you typed `astrona run`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-02/labs/lab-03
```

Run it now and after every step. It runs four checks. All four fail at the start.

| Check | Turns green when |
| --- | --- |
| `composition-repaired` | The Composition names the installed function and the request still uses it |
| `request-synced-ready` | `outpost-env` is `Synced` and `Ready` and owns two composed Objects |
| `service-selects-pods` | The Service selects `app: scout` and has endpoints |
| `request-answers-200` | `shuttle` gets `200` from `http://scout:9898` |

## Step 1: Read the status of the request

Read the request before you change anything. Start with its conditions, then its events:

```sh
kubectl -n outpost get teamenvironment outpost-env
kubectl -n outpost describe teamenvironment outpost-env
kubectl get functions
```

The `Synced` condition is not `True`, and the message names a function that Crossplane cannot find: `function-patch-and-transfrom`. The list of functions has only `function-patch-and-transform`. The names differ by one letter. Crossplane could not run the pipeline, so it created nothing. No check turns green in this step.

## Step 2: Fix the function name

Read the Composition and find the `functionRef`:

```sh
kubectl get composition teamenvironment -o yaml
```

Save the repaired Composition as `composition-teamenvironment.yaml`. It has the correct function name. It also has the correct Service selector, the second fault, which you find in step 3. The selector of the `service` resource must match the label `app: scout` of the Deployment pods:

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

Two lines differ from the broken Composition: `name: function-patch-and-transform` in the `functionRef`, and `app: scout` in the Service selector. Apply it:

```sh
kubectl apply -f composition-teamenvironment.yaml
```

Run the check. `composition-repaired` turns green. The other checks may turn green a little later, after Crossplane has run the pipeline and the provider has created the objects.

## Step 3: Follow what Crossplane created

Wait for the request to become ready, then trace it:

```sh
kubectl -n outpost wait teamenvironment outpost-env --for=condition=Ready --timeout=180s
crossplane resource trace teamenvironment outpost-env -n outpost
```

The trace shows the `TeamEnvironment` and two `Object` resources below it. Run the check. `request-synced-ready` turns green.

If you had fixed only the function name in step 2, the request would be `Ready` but the Service would not work. Look at why:

```sh
kubectl -n outpost get service scout -o jsonpath='{.spec.selector}{"\n"}'
kubectl -n outpost get pods --show-labels
kubectl -n outpost get endpointslices
```

A Service sends traffic only to pods whose labels match its selector. A selector of `app: scouts` matches no pod, because the pods carry `app: scout`. The Service then has no endpoints. `Ready` only means that the objects exist. It does not mean that they work together.

## Step 4: Prove the workload

Send a request from `shuttle` to the Service:

```sh
kubectl -n outpost exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://scout:9898
```

The output is `200`. Run the check. `service-selects-pods` and `request-answers-200` are green.

## Step 5: Submit

When all four checks are green, submit:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-02/labs/lab-03
```

## If a check stays red

- **`composition-repaired` fails with the wrong function.** The `functionRef` name must equal the name in `kubectl get functions` exactly: `function-patch-and-transform`.
- **`composition-repaired` fails because the request was replaced.** You deleted and created `outpost-env` again. A deleted request cannot get its identity back. Start over with `astrona reset`, and edit `teamenvironment` only.
- **`composition-repaired` fails with another Composition.** You created a new Composition and moved the request to it. Repair `teamenvironment` itself.
- **`request-synced-ready` stays red.** Read the conditions again. Crossplane needs a short time to run the pipeline after each change. Run `kubectl -n outpost describe teamenvironment outpost-env` and read the events.
- **`service-selects-pods` fails with `app='scouts'`.** The Service selector in the Composition does not match the pod label. Change the selector in the Composition. An edit of the Service by hand does not change the `Object` or the Composition, and the grader compares all three.
- **`request-answers-200` fails after the other checks pass.** The provider updates the Service at its next reconcile. Wait half a minute and run the check again.
