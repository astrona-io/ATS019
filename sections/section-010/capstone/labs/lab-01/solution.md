# Solution Walkthrough

You work on the `terminal` of the lab cluster. You change one object, the CRD `databases.platform.starfleet.io`, in two steps. You never touch `orders-db` or `billing-db`. The API server keeps them, because you update the CRD in place.

| Goal | Where it lives in the CRD |
| --- | --- |
| Two versions, `v1` stored | `spec.versions[].served` and `spec.versions[].storage` |
| Refuse bad input | `openAPIV3Schema`: `required`, `enum`, `minimum`, `maximum`, `minLength`, `maxLength` |
| Defaults | `default` on `storageGB` and `replicas` |
| Rules across fields and over time | `x-kubernetes-validations` with `self` and `oldSelf` |
| Deprecate the old version | `deprecated` and `deprecationWarning` on `v1alpha1` |
| Separate `status` and `kubectl scale` | `subresources.status` and `subresources.scale` on `v1` |
| Useful `kubectl get` output | `additionalPrinterColumns` on `v1` and `names.shortNames` |

## The feedback loop

Grading runs from the host terminal, the shell where you typed `astrona run`, not inside the cluster:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

The grader has seven checks: `crd-published`, `input-validation`, `cel-rules`, `status-subresource`, `scale-subresource`, `versions-and-existing-objects` and `printer-columns`. All of them fail at the start. Run the command after every step and read which checks turn green.

---

## Step 1: Look at the starting state

Read the versions of the CRD and the two objects:

```sh
kubectl get crd databases.platform.starfleet.io \
  -o jsonpath='{range .spec.versions[*]}{.name}{" served="}{.served}{" storage="}{.storage}{"\n"}{end}'
kubectl -n outpost get databases.v1alpha1.platform.starfleet.io
```

The CRD has one version, `v1alpha1`, which is served and stored. `orders-db` and `billing-db` exist. The table has only a name and an age.

Now prove that the weak schema accepts a misspelled field. A server-side dry run sends the request through the whole API server and stores nothing:

```sh
kubectl create --dry-run=server -f - <<'YAML'
apiVersion: platform.starfleet.io/v1alpha1
kind: Database
metadata:
  name: typo
  namespace: outpost
spec:
  team: grader
  engine: oracle
  replcas: 900
YAML
```

The API server accepts it, because `spec` keeps unknown fields. No check turns green in this step.

---

## Step 2: Publish both versions with the schema and the rules

Both versions need the same schema, so you write it twice. The `v1alpha1` version stays served, is not the storage version and is marked deprecated. The `v1` version is the storage version.

Save this as `crd-database.yaml`:

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: databases.platform.starfleet.io
spec:
  group: platform.starfleet.io
  scope: Namespaced
  names:
    kind: Database
    plural: databases
    singular: database
  conversion:
    strategy: None
  versions:
    - name: v1alpha1
      served: true
      storage: false
      deprecated: true
      deprecationWarning: "platform.starfleet.io/v1alpha1 Database is deprecated; use platform.starfleet.io/v1"
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
                - engine
              x-kubernetes-validations:
                - rule: "self.replicas == 1 || self.storageGB >= 20"
                  message: "more than 1 replica needs at least 20 GB of storage"
              properties:
                team:
                  type: string
                  minLength: 1
                  maxLength: 30
                  x-kubernetes-validations:
                    - rule: "self == oldSelf"
                      message: "team cannot be changed after creation"
                engine:
                  type: string
                  enum:
                    - postgres
                    - mysql
                storageGB:
                  type: integer
                  minimum: 1
                  maximum: 500
                  default: 10
                  x-kubernetes-validations:
                    - rule: "self >= oldSelf"
                      message: "storage can grow but cannot shrink"
                replicas:
                  type: integer
                  minimum: 1
                  maximum: 5
                  default: 1
            status:
              type: object
              properties:
                readyReplicas:
                  type: integer
                  minimum: 0
                phase:
                  type: string
    - name: v1
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
                - engine
              x-kubernetes-validations:
                - rule: "self.replicas == 1 || self.storageGB >= 20"
                  message: "more than 1 replica needs at least 20 GB of storage"
              properties:
                team:
                  type: string
                  minLength: 1
                  maxLength: 30
                  x-kubernetes-validations:
                    - rule: "self == oldSelf"
                      message: "team cannot be changed after creation"
                engine:
                  type: string
                  enum:
                    - postgres
                    - mysql
                storageGB:
                  type: integer
                  minimum: 1
                  maximum: 500
                  default: 10
                  x-kubernetes-validations:
                    - rule: "self >= oldSelf"
                      message: "storage can grow but cannot shrink"
                replicas:
                  type: integer
                  minimum: 1
                  maximum: 5
                  default: 1
            status:
              type: object
              properties:
                readyReplicas:
                  type: integer
                  minimum: 0
                phase:
                  type: string
```

- `conversion.strategy: None` makes the API server change only `apiVersion` when it converts between versions. This is safe because both versions have the same fields.
- `required: [spec]` at the top and `required: [team, engine]` inside `spec` refuse an object without them.
- `default: 10` and `default: 1` fill `storageGB` and `replicas` before validation, so the rules on `spec` can always read them.
- `self >= oldSelf` on `storageGB` is a transition rule: it compares the new value with the stored one, so it runs only on updates. `self == oldSelf` on `team` makes the team immutable.
- `self.replicas == 1 || self.storageGB >= 20` on `spec` is a cross-field rule. It reads two fields at once.
- Unknown fields such as `replcas` are refused because the schema has no `x-kubernetes-preserve-unknown-fields`. `kubectl` sends strict field validation, so the error says `unknown field`.

Apply it:

```sh
kubectl apply -f crd-database.yaml
```

Run the check. The checks `crd-published`, `input-validation`, `cel-rules` and `versions-and-existing-objects` now pass. The checks `status-subresource`, `scale-subresource` and `printer-columns` still fail, because `v1` has no subresources and no columns yet.

Prove the rules yourself with dry runs and patches that must be refused:

```sh
kubectl -n outpost patch databases.v1.platform.starfleet.io orders-db --type merge --dry-run=server -p '{"spec":{"storageGB":20}}'
kubectl -n outpost patch databases.v1.platform.starfleet.io orders-db --type merge --dry-run=server -p '{"spec":{"team":"starfleet"}}'
kubectl -n outpost patch databases.v1.platform.starfleet.io billing-db --type merge --dry-run=server -p '{"spec":{"replicas":3}}'
```

The API server refuses all three, each with the message of its rule. Read the old object through the deprecated version to see the warning on standard error:

```sh
kubectl -n outpost get databases.v1alpha1.platform.starfleet.io orders-db
```

The command succeeds and `kubectl` prints the line `Warning: platform.starfleet.io/v1alpha1 Database is deprecated; use platform.starfleet.io/v1`.

---

## Step 3: Add the subresources, the columns and the short name

These three features belong to `v1`. In `crd-database.yaml`, add this block under `names:` after `singular: database`:

```yaml
    shortNames:
      - db
```

Then add this block in the `v1` version, directly after the line `storage: true`:

```yaml
      subresources:
        status: {}
        scale:
          specReplicasPath: .spec.replicas
          statusReplicasPath: .status.readyReplicas
      additionalPrinterColumns:
        - name: Engine
          type: string
          jsonPath: .spec.engine
        - name: Storage
          type: integer
          jsonPath: .spec.storageGB
        - name: Replicas
          type: integer
          jsonPath: .spec.replicas
        - name: Ready
          type: integer
          jsonPath: .status.readyReplicas
        - name: Age
          type: date
          jsonPath: .metadata.creationTimestamp
```

- `status: {}` turns on the `/status` endpoint. After that, a write to the main endpoint ignores `status`, and a write to `/status` ignores `spec`.
- `specReplicasPath` is the field that `kubectl scale` writes. `statusReplicasPath` is the field that the scale endpoint reports as observed replicas.
- `Age` is listed by hand, because once a CRD lists printer columns the API server no longer adds it. `NAME` is always the first column.

Apply the file again:

```sh
kubectl apply -f crd-database.yaml
```

Run the check. All seven checks now pass.

---

## Step 4: Try the new endpoints

Act as the controller. Scale `orders-db`, then write its status through the status endpoint, then read the table:

```sh
kubectl -n outpost scale databases.v1.platform.starfleet.io/orders-db --replicas=3
kubectl -n outpost patch databases.v1.platform.starfleet.io orders-db \
  --subresource=status --type merge -p '{"status":{"readyReplicas":3,"phase":"Ready"}}'
kubectl -n outpost get db
```

The table shows `postgres`, `50`, `3` and `3` for `orders-db`. This changes `orders-db`, which is fine for the task: the grader only checks its team, engine and storage, and its UID. If you scale `billing-db` the same way, the API server refuses it, because it has only 10 GB.

---

## Step 5: Submit

When all seven checks are green, run the submit command once more:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

---

## If a check stays red

- **`crd-published` says the schema sets `x-kubernetes-preserve-unknown-fields`.** The shortcut hides schema errors instead of fixing them. Declare every field of `spec` and `status`.
- **`crd-published` says `v1` must be the storage version.** Only one version can have `storage: true`. Set it on `v1` and `false` on `v1alpha1`.
- **`input-validation` says a bad value was accepted in `v1alpha1`.** The old version needs the same schema as `v1`. A client that still uses it would skip your rules.
- **`input-validation` says the defaults are wrong.** The defaults are `storageGB: 10` and `replicas: 1`, set with `default` in the schema.
- **`cel-rules` says a valid change was refused.** A rule such as `self == oldSelf` on `storageGB` blocks growth too. Use `self >= oldSelf`.
- **`cel-rules` says the cross-field rule is wrong.** Check both sides: 3 replicas on 10 GB must fail, 3 replicas on 20 GB or more must pass.
- **`status-subresource` says a write to the main endpoint changed status.** Add `subresources.status: {}` to `v1`.
- **`status-subresource` says status was not stored.** The schema must declare `status.readyReplicas` (integer) and `status.phase` (text), or the API server prunes them.
- **`scale-subresource` says the wrong field changed.** `specReplicasPath` must be `.spec.replicas`, not `.spec.storageGB`.
- **`versions-and-existing-objects` says the UID changed.** You deleted the CRD or an object. Deleting a CRD deletes all its objects, and a recreated object is a new object. The grader keeps the original UIDs, so this cannot be repaired by recreating the objects with the same data.
- **`versions-and-existing-objects` says the warning text is wrong.** The `deprecationWarning` must match the task text exactly.
- **`printer-columns` says the row is wrong.** The `jsonPath` of a column must match its header. `Ready` reads `.status.readyReplicas`.
