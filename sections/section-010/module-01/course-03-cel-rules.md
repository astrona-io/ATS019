# Rules Across Fields With CEL

Some rules cannot be written as a limit on one field. A small environment may run at most two replicas, but a large one may run five, so the limit on `replicas` depends on `size`. A team name must never change after the environment is created, so the rule depends on the value the field had before. This part adds both rules to the CRD with CEL, and proves each one with a request the API server must refuse.

## CEL rules in a CRD

CEL, the Common Expression Language, is a small expression language that the API server evaluates itself, with no webhook. A rule lives in a list called `x-kubernetes-validations` on any field of the schema. Each entry has a `rule`, an expression that must be `true`, and a `message` that the API server returns when it is `false`.

Inside a rule, `self` is the field the rule is attached to. A rule on `spec` sees the whole `spec`, so it can compare `self.size` with `self.replicas`. A rule that uses `oldSelf` is a **transition rule**: `oldSelf` is the value before the update, so the rule runs only on updates and can forbid a change.

<!-- astrona:playground:renew -->

Update `crd-teamenvironment.yaml`. The file is the same as before with two new `x-kubernetes-validations` blocks, one on `spec` and one on `team`. Save this as `crd-teamenvironment.yaml`:

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

Read the first rule as "the size is not small, or there are at most two replicas". It can use `self.replicas` without checking that the field exists, because `replicas` has a default and defaulting runs before validation. For a field without a default, write `!has(self.replicas) || self.replicas <= 2`, or the rule fails with an error when the field is missing.

Apply the CRD:

```sh
kubectl apply -f crd-teamenvironment.yaml
```

You should see:

```text
customresourcedefinition.apiextensions.k8s.io/teamenvironments.platform.starfleet.io configured
```

The API server checks every rule when you apply the CRD. A rule with a syntax error, or one the API server estimates as too expensive to run, makes the CRD apply fail, so a broken rule never reaches users.

## Prove the cross-field rule

A rule you have not seen refuse something is a rule you cannot trust. Save this as `teamenvironment-theta.yaml`:

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

Apply it:

```sh
kubectl apply -f teamenvironment-theta.yaml
```

You should see:

```text
The TeamEnvironment "theta" is invalid: spec: Invalid value: a small environment runs at most 2 replicas
```

Every field is valid on its own: `small` is in the `enum` and `3` is below the `maximum` of 5. Only the CEL rule on `spec` sees both fields together. The message is the one you wrote, and the path `spec` says which rule it came from.

The rule runs on updates too. `delta` is a `medium` environment with 1 replica. Make it small, then ask for 4 replicas:

```sh
kubectl -n outpost patch teamenvironment delta --type merge -p '{"spec":{"size":"small"}}'
kubectl -n outpost patch teamenvironment delta --type merge -p '{"spec":{"replicas":4}}'
```

You should see:

```text
teamenvironment.platform.starfleet.io/delta patched
The TeamEnvironment "delta" is invalid: spec: Invalid value: a small environment runs at most 2 replicas
```

## Prove the transition rule

Now try to move `delta` to another team:

```sh
kubectl -n outpost patch teamenvironment delta --type merge -p '{"spec":{"team":"starfleet"}}'
```

You should see:

```text
The TeamEnvironment "delta" is invalid: spec.team: Invalid value: "starfleet": team cannot be changed after creation
```

`self == oldSelf` compares the new team with the stored one. On a create there is no old value, so transition rules are skipped and any valid team is accepted. That is the usual way to make a field immutable.

## Test without storing anything

Testing with real objects leaves objects behind. A **server-side dry run** sends the request through every step of the API server, including pruning, defaulting, schema validation and CEL rules, and then stores nothing:

```sh
kubectl apply --dry-run=server -f teamenvironment-epsilon.yaml
```

You should see:

```text
The TeamEnvironment "epsilon" is invalid: 
* spec.size: Unsupported value: "huge": supported values: "small", "medium", "large"
* spec.contact: Invalid value: "nobody": spec.contact in body should match '^[a-z0-9.-]+@[a-z0-9.-]+$'
* spec.replicas: Invalid value: 50: spec.replicas in body should be less than or equal to 5
* <nil>: Invalid value: null: some validation rules were not checked because the object was invalid; correct the existing errors to complete validation
```

The last line is new. When the schema checks already fail, the API server skips the CEL rules and says so. Fix the schema errors first, then run the dry run again to see the CEL result. With `replicas: 2`, the dry run of `theta` succeeds and prints `teamenvironment.platform.starfleet.io/theta created (server dry run)`, and nothing is stored.

You can now write CEL rules that compare fields with each other and transition rules that compare a new value with the old one, and prove each rule with a request it must refuse. Together with the structural schema, the API server now refuses every bad object from the start of this module. The open question is a practical one: `kubectl get` still shows only a name and an age.

## Common pitfalls

> [!WARNING]
> - **Reading a field that may be missing.** `self.replicas` fails when the field is absent and has no default. Guard it with `has(self.replicas)`.
> - **Expecting a transition rule to run on create.** Rules with `oldSelf` only run on updates.
> - **Trusting a rule you never saw fail.** Send one request that must be refused, ideally with `--dry-run=server`.
> - **Reading only the first error line.** When schema checks fail, CEL rules are skipped, and the last line says so.
