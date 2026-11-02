# Solution Walkthrough

You work on the `terminal` of the lab cluster. You read the weak schema, replace it with a structural schema, and prove that the API server refuses bad input. The CRD keeps its name, kind and version, and the object `alpha` stays.

| Goal | Where it lives | Field or command |
| --- | --- | --- |
| Refuse a missing field | `required` list on the object that holds the fields | `required: [team, size, contact]` under `spec` |
| Limit a value | the field's schema | `enum`, `minimum`, `maximum`, `minLength`, `maxLength`, `pattern` |
| Fill in a missing value | the field's schema | `default` |
| Drop an unknown field | the whole schema | list `properties` and do not set `x-kubernetes-preserve-unknown-fields` |
| Test without storing | the API server | `kubectl apply --dry-run=server` |

## The feedback loop

Grading runs from the host terminal, the shell where you typed `astrona run`, not inside the cluster:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

The grader has three checks: `rejects-bad-values`, `defaults-and-pruning` and `crd-kept`. At the start, `crd-kept` passes because the CRD and `alpha` exist. The other two fail because the weak schema accepts everything. Run the command after each step and read the results.

---

## Step 1: Read the weak schema and prove it accepts bad input

Print the schema of the CRD:

```sh
kubectl get crd teamenvironments.platform.starfleet.io -o jsonpath='{.spec.versions[0].schema.openAPIV3Schema}{"\n"}'
```

The schema declares only `spec` as an object and sets `x-kubernetes-preserve-unknown-fields: true`. The API server keeps every field under `spec` and checks none. No check turns green in this step.

---

## Step 2: Write the typed schema

Save this as `crd-teamenvironment.yaml`:

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
  versions:
    - name: v1alpha1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          required:
            - spec
          properties:
            spec:
              type: object
              required:
                - team
                - size
                - contact
              properties:
                team:
                  type: string
                  minLength: 1
                  maxLength: 30
                size:
                  type: string
                  enum:
                    - small
                    - medium
                    - large
                replicas:
                  type: integer
                  minimum: 1
                  maximum: 5
                  default: 1
                contact:
                  type: string
                  pattern: '^[a-z0-9.-]+@[a-z0-9.-]+$'
                retentionDays:
                  type: integer
                  minimum: 1
                  maximum: 90
                  default: 7
```

- `required` is a list on the object that holds the fields. It is not a `true` on each field.
- `enum`, `minimum`, `maximum`, `minLength`, `maxLength` and `pattern` limit one field each.
- `default` is the value the API server writes when the field is missing.
- There is no `x-kubernetes-preserve-unknown-fields`, so the API server prunes fields that the schema does not declare.

Apply it:

```sh
kubectl apply -f crd-teamenvironment.yaml
```

The API server needs a few seconds to serve the new schema. Run the check. `crd-kept` still passes, and `rejects-bad-values` and `defaults-and-pruning` now pass too.

---

## Step 3: Prove the schema with objects that must fail

Save this as `teamenvironment-epsilon.yaml`:

```yaml
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: epsilon
  namespace: outpost
spec:
  team: outpost
  size: huge
  replicas: 50
  contact: nobody
```

Test it without storing anything:

```sh
kubectl apply --dry-run=server -f teamenvironment-epsilon.yaml
```

The API server refuses the object and names `spec.size`, `spec.replicas` and `spec.contact` in one answer. Change one value at a time to a valid one and run the command again to see each error go away. Then check the defaults with a valid object that has no `replicas` and no `retentionDays`. Save this as `teamenvironment-delta.yaml`:

```yaml
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: delta
  namespace: outpost
spec:
  team: outpost
  size: medium
  contact: lead@outpost.starfleet.io
```

Test it:

```sh
kubectl apply --dry-run=server -o yaml -f teamenvironment-delta.yaml
```

The output shows `replicas: 1` and `retentionDays: 7`, which the API server filled in.

---

## Step 4: Submit

When all three checks are green, run the submit command once more:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

---

## If a check stays red

- **`rejects-bad-values` fails with "the API server accepted ...".** The new schema is not served yet, or a field has no limit. Wait a few seconds and run the check again. Then compare the field named in the message with the schema.
- **`rejects-bad-values` fails with "the error does not name spec.<field>".** The API server refused the object for another reason. Check that the limit sits on the right field and that `required` is a list on `spec`, not on the top level.
- **`defaults-and-pruning` fails with "does not get replicas 1".** The `default` is missing or sits on the wrong field. A `default` belongs inside `replicas` and `retentionDays`.
- **`defaults-and-pruning` fails with "still uses x-kubernetes-preserve-unknown-fields".** Remove the field from every level of the schema. It turns off pruning, so typos are stored and never reported.
- **`defaults-and-pruning` fails with "the field replcas is kept".** The schema keeps unknown fields somewhere, for example with `x-kubernetes-preserve-unknown-fields` on a nested object. Remove it.
- **`crd-kept` fails.** You deleted and recreated the CRD, changed the version name, or deleted `alpha`. Deleting a CRD deletes all of its objects. Apply the file over the existing CRD instead.
