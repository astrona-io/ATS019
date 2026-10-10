# Types, Required Fields, Defaults And Pruning

The weak schema stores whatever it is given. A real platform API must say which fields exist, which are required, what values they may hold, and what they are when the user leaves them out. This part replaces the weak schema with a typed one. It then tests the new schema on new objects, and on the objects that were stored before the change, which behave differently.

## A structural schema

A **structural schema** is a schema where every field has a `type`, and where object fields list their `properties`. CRDs in `apiextensions.k8s.io/v1` must have one. Only a structural schema lets the API server prune, default and validate, because it can only work on fields it knows.

<!-- astrona:playground:renew -->

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

The schema uses these keywords:

- `type` is `object`, `string`, `integer`, `number`, `boolean` or `array`.
- `required` lists the fields that must be present, at the level of the object that holds them.
- `enum` lists the only values allowed.
- `minimum` and `maximum` limit numbers; `minLength` and `maxLength` limit strings.
- `pattern` is a regular expression a string must match.
- `default` is the value the API server writes when the field is missing.

`x-kubernetes-preserve-unknown-fields` is gone, so pruning is now on for the whole object. Apply the new CRD:

```sh
kubectl apply -f crd-teamenvironment.yaml
```

You should see:

```text
customresourcedefinition.apiextensions.k8s.io/teamenvironments.platform.starfleet.io configured
```

## New objects: rejected, defaulted, pruned

Start with an object that breaks three limits at once. Save this as `teamenvironment-epsilon.yaml`:

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

Apply it:

```sh
kubectl apply -f teamenvironment-epsilon.yaml
```

You should see:

```text
The TeamEnvironment "epsilon" is invalid: 
* spec.contact: Invalid value: "nobody": spec.contact in body should match '^[a-z0-9.-]+@[a-z0-9.-]+$'
* spec.replicas: Invalid value: 50: spec.replicas in body should be less than or equal to 5
* spec.size: Unsupported value: "huge": supported values: "small", "medium", "large"
```

The API server lists every schema error in one answer, each with the field path and the rule that failed. Nothing was stored. A missing required field gets its own message: an object with only `size: small` in its `spec` is refused with `spec.team: Required value` and `spec.contact: Required value`.

Now leave out the two fields that have defaults. Save this as `teamenvironment-delta.yaml`:

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

Apply it, then read back its `spec`:

```sh
kubectl apply -f teamenvironment-delta.yaml
kubectl -n outpost get teamenvironment delta -o jsonpath='{.spec}{"\n"}'
```

You should see:

```text
teamenvironment.platform.starfleet.io/delta created
{"contact":"lead@outpost.starfleet.io","replicas":1,"retentionDays":7,"size":"medium","team":"outpost"}
```

The API server wrote `replicas: 1` and `retentionDays: 7`. Defaulting happens inside the API server before the object is stored, so every reader of the object, including a controller, sees the same complete `spec`.

Last, the misspelled field. Save this as `teamenvironment-zeta.yaml`:

```yaml
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: zeta
  namespace: outpost
spec:
  team: outpost
  size: small
  replcas: 2
  contact: lead@outpost.starfleet.io
```

Apply it:

```sh
kubectl apply -f teamenvironment-zeta.yaml
```

You should see:

```text
Error from server (BadRequest): error when creating "teamenvironment-zeta.yaml": TeamEnvironment in version "v1alpha1" cannot be handled as a TeamEnvironment: strict decoding error: unknown field "spec.replcas"
```

This is not pruning. `kubectl` asks the API server for **strict field validation** by default, so the API server refuses a request that contains a field the schema does not know. That is the behaviour you want for people. Programs that send requests without strict validation get pruning instead. You can see it by turning strict validation off for one request:

```sh
kubectl apply -f teamenvironment-zeta.yaml --validate=false
kubectl -n outpost get teamenvironment zeta -o jsonpath='{.spec}{"\n"}'
```

You should see:

```text
teamenvironment.platform.starfleet.io/zeta created
{"contact":"lead@outpost.starfleet.io","replicas":1,"retentionDays":7,"size":"small","team":"outpost"}
```

The API server dropped `replcas` without a word and then defaulted `replicas` to `1`. That is exactly why a typo in a pruned schema is dangerous for a client that does not ask for strict validation: the user asked for 2 replicas and silently got 1.

## Objects stored before the change

The objects `beta` and `gamma` were stored under the weak schema. Changing the CRD does not rewrite etcd, so read them again:

```sh
kubectl -n outpost get teamenvironment beta -o jsonpath='{.spec}{"\n"}'
kubectl -n outpost get teamenvironment gamma -o jsonpath='{.spec}{"\n"}'
```

You should see:

```text
{"contact":"lead@outpost.starfleet.io","replicas":1,"retentionDays":7,"size":"medium","team":"outpost"}
{"contact":"nobody","replicas":50,"retentionDays":7,"size":"huge","team":"outpost"}
```

The API server prunes and defaults on **reads** too. `beta` comes back without `replcas` and with both defaults, although etcd still holds the old data. Validation, however, runs only on writes. `gamma` is still served with size `huge` and 50 replicas, values the schema now forbids.

What happens when someone updates `gamma`? Kubernetes 1.35 uses **validation ratcheting**: an update may keep a value that is already invalid, as long as that value does not change. Try three updates:

```sh
kubectl -n outpost patch teamenvironment gamma --type merge -p '{"spec":{"contact":"lead@outpost.starfleet.io"}}'
kubectl -n outpost patch teamenvironment gamma --type merge -p '{"spec":{"replicas":40}}'
kubectl -n outpost patch teamenvironment gamma --type merge -p '{"spec":{"replicas":3}}'
```

You should see:

```text
teamenvironment.platform.starfleet.io/gamma patched
The TeamEnvironment "gamma" is invalid: spec.replicas: Invalid value: 40: spec.replicas in body should be less than or equal to 5
teamenvironment.platform.starfleet.io/gamma patched
```

The first update fixed the contact and was accepted, although `size: huge` and `replicas: 50` were still invalid: they did not change. The second update changed `replicas` to another invalid value and was refused. The third changed it to a valid value and was accepted. `size: huge` is still stored. Ratcheting lets teams keep working with old objects, so a schema change never blocks every update at once, but the old bad values stay until someone changes them.

`kubectl explain` now has something to show, because it reads the same schema (if it prints `error: field "size" does not exist`, the API server has not published the new schema yet; wait a few seconds and run it again):

```sh
kubectl explain teamenvironment.spec.size
```

You should see:

```text
GROUP:      platform.starfleet.io
KIND:       TeamEnvironment
VERSION:    v1alpha1

FIELD: size <string>
ENUM:
    small
    medium
    large

DESCRIPTION:
    <empty>
```

A `description` on each field in the schema would fill in that empty `DESCRIPTION`, and it is worth adding for any API other teams will use.

You can now write a structural schema that types every field, requires the ones that matter, limits their values and fills in defaults. You have seen that the API server prunes and defaults on every read, but validates only on writes, so stored objects keep values a new schema forbids until they change. The open question is how to express a rule that one field's limit cannot: a rule that depends on two fields, or on the value a field had before.

## Common pitfalls

> [!WARNING]
> - **Putting `required` on the field itself.** `required` is a list on the object that holds the fields, not a `true` on each field.
> - **Expecting a new schema to fix stored objects.** Validation runs on writes only. Old values stay until an update changes them.
> - **Testing typos only with `kubectl`.** `kubectl` uses strict validation and refuses unknown fields; other clients get silent pruning.
> - **Forgetting that defaults change what a controller sees.** A default in the schema is written into every object, so it becomes part of your API.
