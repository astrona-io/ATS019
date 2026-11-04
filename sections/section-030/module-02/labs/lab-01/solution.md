# Solution Walkthrough

You write one XRD and one request on the terminal where you started the lab. You change nothing else. Crossplane, the provider and the function stay as they are.

| Goal | Where it lives | Command or file |
| --- | --- | --- |
| Define the API | `CompositeResourceDefinition` (cluster-wide) | `xrd-probeenvironment.yaml`, `kubectl apply` |
| Wait for the new type | `Established` condition of the XRD | `kubectl wait xrd ... --for=condition=Established` |
| Make the API server refuse bad input | `openAPIV3Schema` in the XRD | `enum`, `minimum`, `maximum`, `required` |
| Ask for one environment | `ProbeEnvironment` in `outpost` | `probeenvironment-first-probe.yaml`, `kubectl apply` |

## The feedback loop

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-02/labs/lab-01
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

It runs four checks. All four fail at the start.

| Check | Turns green when |
| --- | --- |
| `xrd-definition` | The XRD is `Established` with the right name, scope, group, kind and version |
| `valid-request-defaults` | A request with only `owner` is accepted and gets `tier: dev` and `instances: 2` |
| `invalid-requests-refused` | Every bad request from the task is refused |
| `stored-request` | `first-probe` exists in `outpost` with the defaults |

## Step 1: Look at the starting state

Check that the cluster has no platform API yet:

```sh
kubectl get xrd
kubectl get providers,functions
```

No XRD is listed. The provider and the function are installed. No check turns green in this step.

## Step 2: Write the XRD

Save this as `xrd-probeenvironment.yaml`:

```yaml
apiVersion: apiextensions.crossplane.io/v2
kind: CompositeResourceDefinition
metadata:
  name: probeenvironments.platform.starfleet.io
spec:
  scope: Namespaced
  group: platform.starfleet.io
  names:
    kind: ProbeEnvironment
    plural: probeenvironments
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
                owner:
                  type: string
                tier:
                  type: string
                  enum: [dev, staging, prod]
                  default: dev
                instances:
                  type: integer
                  minimum: 1
                  maximum: 5
                  default: 2
                contactEmail:
                  type: string
              required:
                - owner
```

These lines matter most:

- `metadata.name` must be the plural name, a dot and the group.
- `scope: Namespaced` makes each request live in a namespace.
- `referenceable: true` marks the version that a Composition may target.
- `enum`, `minimum`, `maximum` and `required` make the API server refuse bad input. `default` fills in a missing value.

Apply it and wait for Crossplane to create the CustomResourceDefinition (CRD):

```sh
kubectl apply -f xrd-probeenvironment.yaml
kubectl wait xrd probeenvironments.platform.starfleet.io --for=condition=Established --timeout=60s
```

Check the watch terminal. `xrd-definition` turns green. `valid-request-defaults` and `invalid-requests-refused` turn green too, because the schema is now in place.

## Step 3: Create the request

Save this as `probeenvironment-first-probe.yaml`:

```yaml
apiVersion: platform.starfleet.io/v1alpha1
kind: ProbeEnvironment
metadata:
  name: first-probe
  namespace: outpost
spec:
  owner: drifter
```

Apply it and read what the API server stored:

```sh
kubectl apply -f probeenvironment-first-probe.yaml
kubectl -n outpost get probeenvironment first-probe -o jsonpath='{.spec}{"\n"}'
```

The stored `spec` shows `owner`, and also `tier` with the value `dev` and `instances` with the value `2`. You did not write those two values. The API server added them from the schema defaults.

Check the watch terminal. `stored-request` turns green.

## Step 4: Try the refusals yourself

The grader refuses nothing for you: it only tests your schema. Try one bad request to see the error. Save this as `probeenvironment-invalid.yaml`:

```yaml
apiVersion: platform.starfleet.io/v1alpha1
kind: ProbeEnvironment
metadata:
  name: too-many
  namespace: outpost
spec:
  owner: drifter
  instances: 6
```

Apply it:

```sh
kubectl apply -f probeenvironment-invalid.yaml
```

The server refuses the request and the message names `spec.instances`. Nothing is stored. A field that the schema does not declare, such as `colour`, is refused as well, because `kubectl` sends the request with strict field validation.

## Step 5: Submit

When all four checks are green, press Ctrl-C to stop the watch and run the submit command once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-02/labs/lab-01
```

## If a check stays red

- **`xrd-definition` fails with "is not Established".** Read the conditions with `kubectl describe xrd probeenvironments.platform.starfleet.io`. A wrong XRD name or a schema error stops Crossplane from creating the CRD.
- **`xrd-definition` fails on the scope.** The field is `spec.scope: Namespaced`. In Crossplane 2.x, `apiextensions.crossplane.io/v2` is required for it.
- **`valid-request-defaults` fails with wrong defaults.** Put `default` inside the property, next to `type`, not next to `properties`.
- **`invalid-requests-refused` fails on an unknown field.** The schema must not contain `x-kubernetes-preserve-unknown-fields: true`. That setting keeps every unknown field instead of refusing it. Remove it.
- **`invalid-requests-refused` fails on the number cases.** Check that `instances` has `minimum: 1` and `maximum: 5`, and that `type` is `integer`.
- **`stored-request` fails.** Apply the request only after the XRD is `Established`. The namespace must be `outpost` and the name `first-probe`.
