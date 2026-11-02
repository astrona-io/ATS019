# Solution Walkthrough

You work on the `terminal` of the lab cluster. You change the CRD in one file: two CEL rules in the schema, and the printer columns, the short name and the category around it. The typed schema, the version and the object `alpha` stay.

| Goal | Where it lives | Field |
| --- | --- | --- |
| Compare two fields | `x-kubernetes-validations` on `spec` | `rule` with `self.size` and `self.replicas` |
| Forbid a change | `x-kubernetes-validations` on `team` | `rule: "self == oldSelf"` |
| Show fields in `kubectl get` | the version of the CRD | `additionalPrinterColumns` |
| Add a short name and a category | `spec.names` of the CRD | `shortNames` and `categories` |
| Test without storing | the API server | `kubectl apply --dry-run=server` |

## The feedback loop

Grading runs from the host terminal, the shell where you typed `astrona run`, not inside the cluster:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-02
```

The grader has three checks: `cel-rules`, `printer-columns` and `schema-kept`. At the start, `schema-kept` passes because the typed schema is in place. `cel-rules` and `printer-columns` fail. Run the command after each step and read the results.

---

## Step 1: Look at the starting state

Read the objects and the type:

```sh
kubectl -n outpost get teamenvironments
kubectl api-resources --api-group=platform.starfleet.io
```

`kubectl get` shows a name and an age only, and the type has no short name. No check turns green in this step.

---

## Step 2: Add the CEL rules

Save this as `crd-teamenvironment.yaml`. It keeps the typed schema and adds one `x-kubernetes-validations` block on `spec` and one on `team`:

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
              x-kubernetes-validations:
                - rule: "self.size != 'small' || self.replicas <= 2"
                  message: "a small environment runs at most 2 replicas"
              properties:
                team:
                  type: string
                  minLength: 1
                  maxLength: 30
                  x-kubernetes-validations:
                    - rule: "self == oldSelf"
                      message: "team cannot be changed after creation"
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

- The rule on `spec` reads as "the size is not small, or there are at most two replicas". `self` is `spec`, so the rule sees both fields. It can use `self.replicas` directly because `replicas` has a default and defaulting runs before validation.
- The rule on `team` uses `oldSelf`, the value before the update. That makes it a transition rule: it runs only on updates, so a new object can have any valid team.

Apply it:

```sh
kubectl apply -f crd-teamenvironment.yaml
```

The API server needs a few seconds to serve the new rules. Run the check. `cel-rules` now passes.

---

## Step 3: Prove the rules with requests that must fail

Save this as `teamenvironment-theta.yaml`:

```yaml
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: theta
  namespace: outpost
spec:
  team: outpost
  size: small
  replicas: 3
  contact: lead@outpost.starfleet.io
```

Test it without storing anything:

```sh
kubectl apply --dry-run=server -f teamenvironment-theta.yaml
```

The API server refuses the object with the message you wrote. Try the transition rule on `alpha` the same way:

```sh
kubectl -n outpost patch teamenvironment alpha --type merge -p '{"spec":{"team":"starfleet"}}' --dry-run=server
```

The API server refuses the change of `spec.team`. No new check turns green in this step.

---

## Step 4: Add the printer columns, the short name and the category

Edit `crd-teamenvironment.yaml`. Add `shortNames` and `categories` under `spec.names`, and add `additionalPrinterColumns` in the version, above `schema`:

```yaml
    shortNames:
      - teamenv
    categories:
      - platform
```

```yaml
      additionalPrinterColumns:
        - name: Team
          type: string
          jsonPath: .spec.team
        - name: Size
          type: string
          jsonPath: .spec.size
        - name: Replicas
          type: integer
          jsonPath: .spec.replicas
        - name: Age
          type: date
          jsonPath: .metadata.creationTimestamp
```

- `shortNames` lists extra names that `kubectl` accepts for the type.
- `categories` puts the type in a named group, so `kubectl get platform` lists it. Do not use `all`.
- Each column has a `name` for the header, a `type` and a `jsonPath` into the object.
- Once you list any column, the API server stops adding `Age` by itself. The last column adds it back with the type `date`.

Apply the file again and read the result:

```sh
kubectl apply -f crd-teamenvironment.yaml
kubectl -n outpost get teamenv
kubectl -n outpost get platform
```

Both `get` commands list `alpha` with its team, size and replicas. Run the check. `printer-columns` now passes.

---

## Step 5: Submit

When all three checks are green, run the submit command once more:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-02
```

---

## If a check stays red

- **`cel-rules` fails with "accepted a small environment with 3 replicas".** The rule is not served yet, or it sits on the wrong field. Wait a few seconds and run the check again. The rule must be on `spec`, because only `spec` sees both `size` and `replicas`.
- **`cel-rules` fails with "refused by a schema limit, not by a CEL rule".** You lowered `maximum` on `replicas`. That also refuses `medium` with 4 replicas. Put the limit in a CEL rule and keep `maximum: 5`.
- **`cel-rules` fails with "refused a valid object".** The rule is too strict, for example `self.replicas < 2`. A small environment may have exactly 2 replicas.
- **`cel-rules` fails on `spec.team`.** The rule `self == oldSelf` must be on the field `team`, not on `spec`. A rule on `spec` that compares the whole object would also refuse changes to other fields.
- **`printer-columns` fails with "the columns are ...".** The header must be `NAME TEAM SIZE REPLICAS AGE`. A missing `Age` column is the usual cause, because listing any column removes the default one.
- **`printer-columns` fails with "the category platform is missing".** Put `platform` under `spec.names.categories`, not under `shortNames`.
- **`schema-kept` fails.** You deleted and recreated the CRD, removed a limit from the schema, or used `x-kubernetes-preserve-unknown-fields`. Deleting a CRD deletes all of its objects. Apply the file over the existing CRD instead.
