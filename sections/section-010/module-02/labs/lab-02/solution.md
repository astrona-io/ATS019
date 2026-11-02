# Solution Walkthrough

You change one CustomResourceDefinition (CRD) and then write to two objects on the `terminal` of the lab cluster. You do not delete anything: the objects `alpha` and `beta` stay in the cluster.

| Goal | Where it lives | Field or command |
| --- | --- | --- |
| A separate endpoint for status | `subresources.status` in the CRD version | `status: {}` |
| Write status | the `/status` endpoint | `kubectl patch --subresource=status --type merge` |
| A standard endpoint to resize | `subresources.scale` in the CRD version | `specReplicasPath` and `statusReplicasPath` |
| Change the desired replicas | the `/scale` endpoint | `kubectl scale --replicas=N` |

## The feedback loop

Grading runs from the host terminal, the shell where you typed `astrona run`, not inside the cluster:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-02
```

The grader has three checks: `status-subresource`, `scale-subresource` and `objects-kept`. The check `objects-kept` passes at the start, because nothing is deleted yet and the schema is intact. The other two fail. Run the command after every step and read which check turns green.

---

## Step 1: Look at the starting state

Read the subresources of the CRD and the replica counts:

```sh
kubectl get crd teamenvironments.platform.starfleet.io -o jsonpath='{.spec.versions[0].subresources}{"\n"}'
kubectl -n outpost get teamenvironments
```

The first command prints an empty line, because the CRD has no subresources. The second command lists `alpha` and `beta`. The `READY` column is empty because no object has a status. No check turns green in this step.

---

## Step 2: Enable both subresources

Save this as `crd-teamenvironment-subresources.yaml`:

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
    - name: v1
      served: true
      storage: true
      subresources:
        status: {}
        scale:
          specReplicasPath: .spec.replicas
          statusReplicasPath: .status.readyReplicas
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

What the new lines do:

- `status: {}` turns on the `/status` endpoint. From then on, normal writes ignore `status` and writes to `/status` ignore `spec`.
- `specReplicasPath: .spec.replicas` tells the API server which field holds the desired replica count for the `Scale` object.
- `statusReplicasPath: .status.readyReplicas` tells it which field holds the observed replica count.
- The schema is the one from the start, with the range `0` to `5` for `spec.replicas`.

Apply it:

```sh
kubectl apply -f crd-teamenvironment-subresources.yaml
```

Then read the `Scale` object of `alpha`:

```sh
kubectl -n outpost get --raw /apis/platform.starfleet.io/v1/namespaces/outpost/teamenvironments/alpha/scale
```

The JSON has `"spec":{"replicas":2}`. The observed count is `0` because `alpha` has no status yet. If the command says the resource is not found, wait a few seconds and run it again.

**Run the check.** `status-subresource` and `scale-subresource` still fail, because no status is written and `beta` is not scaled. `objects-kept` stays green.

---

## Step 3: Write the status of alpha

Act like the controller and write status through the `/status` endpoint:

```sh
kubectl -n outpost patch teamenvironment alpha --subresource=status --type merge \
  -p '{"status":{"readyReplicas":2,"phase":"Ready"}}'
kubectl -n outpost get teamenvironment alpha
```

The `READY` column of `alpha` now shows `2`. A patch without `--subresource=status` would leave `status` empty, because the main endpoint ignores it.

---

## Step 4: Scale beta and write its status

`kubectl scale` changes `spec.replicas` through the `/scale` endpoint:

```sh
kubectl -n outpost scale teamenvironment beta --replicas=4
```

It does not touch `status`. Write the observed state, again as the controller:

```sh
kubectl -n outpost patch teamenvironment beta --subresource=status --type merge \
  -p '{"status":{"readyReplicas":4,"phase":"Ready"}}'
kubectl -n outpost get teamenvironments
```

Both objects now show their replica count and their ready count.

**Run the check.** `status-subresource` and `scale-subresource` now pass.

---

## Step 5: Submit

When all three checks are green, submit:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-02
```

---

## If a check stays red

- **`status-subresource` fails: "does not enable the status subresource".** The `subresources` block is under the wrong version, or the CRD was not applied. Read the CRD again with the command from Step 1.
- **`status-subresource` fails: "alpha status is ''".** You wrote status with `kubectl apply` or a patch without `--subresource=status`. The API server ignored it. Use `--subresource=status`.
- **`status-subresource` fails: "a normal write changed status.phase".** Another mechanism lets the main endpoint write status. Remove it. Only the `status` subresource may protect the field.
- **`scale-subresource` fails: "specReplicasPath is ..." or "statusReplicasPath is ...".** A path has a typo or points at another field. The grader expects exactly `.spec.replicas` and `.status.readyReplicas`.
- **`scale-subresource` fails: "beta: Scale spec.replicas is not 4".** `beta` was not scaled, or you edited `spec.replicas` and then lost the change. Run `kubectl scale` again.
- **`scale-subresource` fails: "scaling alpha to 9 replicas was accepted".** The schema lost its `maximum: 5`. Put the original schema back in the CRD.
- **`objects-kept` fails: "is not the original object".** You deleted and created `alpha` or `beta` again, or you deleted the CRD. The grader compares the object uid with the uid from the start. Reset the lab with `astrona destroy ats-019-lab-010-02-02` and start again.
