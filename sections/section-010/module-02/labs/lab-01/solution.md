# Solution Walkthrough

You change one CustomResourceDefinition (CRD) and create one object on the `terminal` of the lab cluster. You do not delete anything: the objects `alpha` and `beta` stay in the cluster.

| Goal | Where it lives | Field or command |
| --- | --- | --- |
| Let clients use a new version | `spec.versions[].served` | `served: true` on `v1` |
| Choose the version written to etcd | `spec.versions[].storage` | `storage: true` on `v1` only |
| Keep the old version, but warn | `spec.versions[]` of `v1alpha1` | `deprecated: true` and `deprecationWarning` |
| Convert between versions | `spec.conversion.strategy` | `None` (only `apiVersion` changes) |
| Read the versions that may be in etcd | CRD `status.storedVersions` | `kubectl get crd ... -o jsonpath` |

## The feedback loop

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch -c sections/section-010/module-02/labs/lab-01
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

The grader has three checks: `versions`, `deprecation` and `objects-and-schema`. All three fail at the start, because the CRD has no `v1` version. The watch terminal shows each check as it turns green.

---

## Step 1: Look at the starting state

Read the versions of the CRD and the two objects:

```sh
kubectl get crd teamenvironments.platform.starfleet.io \
  -o jsonpath='{range .spec.versions[*]}{.name}{" served="}{.served}{" storage="}{.storage}{"\n"}{end}'
kubectl -n outpost get teamenvironments
```

The CRD has one version, `v1alpha1`, which is served and stored. The second command lists `alpha` and `beta`. No check turns green in this step.

---

## Step 2: Write the two-version CRD

The CRD needs both versions with the same schema. Save this as `crd-teamenvironment-versions.yaml`:

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

What the important lines do:

- `conversion.strategy: None` tells the API server to change only the `apiVersion` field when it serves an object through another version. This is safe because both schemas are the same.
- `served: true` on both versions keeps `v1alpha1` available for the `outpost` scripts and adds `v1`.
- `storage: false` on `v1alpha1` and `storage: true` on `v1` make `v1` the only storage version. Two versions with `storage: true` make the API server refuse the CRD.
- `deprecated: true` and `deprecationWarning` on `v1alpha1` make `kubectl` print the warning when a client uses that version.
- The `v1` schema is a copy of the `v1alpha1` schema. Both keep the enum, the range and the default, so both reject bad input.

Apply it:

```sh
kubectl apply -f crd-teamenvironment-versions.yaml
```

Then check the result:

```sh
kubectl get crd teamenvironments.platform.starfleet.io \
  -o jsonpath='{range .spec.versions[*]}{.name}{" served="}{.served}{" storage="}{.storage}{"\n"}{end}'
kubectl get crd teamenvironments.platform.starfleet.io -o jsonpath='{.status.storedVersions}{"\n"}'
```

`v1alpha1` shows `storage=false` and `v1` shows `storage=true`. `status.storedVersions` lists both versions, because `alpha` and `beta` are still stored as `v1alpha1`. Kubernetes does not rewrite old objects when the storage version changes.

**Check the watch terminal.** `versions` and `deprecation` now pass. If `deprecation` still fails, wait a few seconds for the next watch result: `kubectl` needs a moment to see the new version.

---

## Step 3: Read the objects through both versions

Name the version in the resource name to choose it:

```sh
kubectl -n outpost get teamenvironments.v1.platform.starfleet.io alpha -o yaml
kubectl -n outpost get teamenvironments.v1alpha1.platform.starfleet.io alpha -o yaml
```

Both commands return the same `spec`. The second command prints the line that starts with `Warning:` on standard error. The first command prints no warning. No check turns green in this step, but it shows what the grader tests.

---

## Step 4: Create gamma through v1

Save this as `teamenvironment-gamma.yaml`:

```yaml
apiVersion: platform.starfleet.io/v1
kind: TeamEnvironment
metadata:
  name: gamma
  namespace: outpost
spec:
  team: outpost
  size: large
  replicas: 4
```

Apply it and read it back:

```sh
kubectl apply -f teamenvironment-gamma.yaml
kubectl -n outpost get teamenvironments.v1.platform.starfleet.io gamma
```

The API server stores `gamma` as `v1`, because `v1` is the storage version. The `outpost` objects `alpha` and `beta` stay stored as `v1alpha1`.

**Check the watch terminal.** `objects-and-schema` now passes.

---

## Step 5: Submit

When all three checks are green, press Ctrl-C to stop the watch and run the submit command once:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

---

## If a check stays red

- **`versions` fails: "v1 must be served and must be the storage version".** `v1` has `storage: false`, or `v1alpha1` still has `storage: true`. Exactly one version may have `storage: true`.
- **`versions` fails: "status.storedVersions ... does not list v1".** The CRD was not changed. Apply the file again and read the CRD.
- **`deprecation` fails: "does not tell users to use platform.starfleet.io/v1".** The `deprecationWarning` text is missing or has another text. Copy the sentence from the task exactly.
- **`deprecation` fails: "prints no deprecation warning".** `deprecated: true` is on `v1`, or `served` is `false` on `v1alpha1`. The warning only appears on a served, deprecated version. `kubectl` prints it on standard error, so a command that hides standard error shows nothing.
- **`objects-and-schema` fails: "is not the original object".** You deleted and created `alpha` or `beta` again, or you deleted the CRD. The grader compares the object uid with the uid from the start. Reset the lab with `astrona destroy ats-019-lab-010-02` and start again.
- **`objects-and-schema` fails: "accepted invalid input".** The schema of one version is missing the enum, the range or the `required` list, or the schema allows unknown fields with `x-kubernetes-preserve-unknown-fields`. Copy the full schema into both versions.
