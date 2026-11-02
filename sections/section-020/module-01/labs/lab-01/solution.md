# Solution Walkthrough

You work on the `terminal` of the lab cluster. You compare `observedGeneration` with `generation`, find that the controller is not running, and start it. The `Prometheus` resource and the StatefulSet stay untouched.

| Goal | Where it lives | Command or object |
| --- | --- | --- |
| Judge whether a status is current | `status.conditions[].observedGeneration` and `metadata.generation` | `kubectl get prometheus starfleet -o jsonpath=...` |
| Find out whether the controller runs | The controller's Deployment | `kubectl -n default get deployment prometheus-operator` |
| Make the controller act | The Deployment replicas | `kubectl scale ... --replicas=1` |
| Prove it acted | The owned StatefulSet and the new status | `--log.level=debug` in the container args, equal generations |

## The feedback loop

Grading runs from the host terminal, the shell where you typed `astrona run`, not inside the cluster:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

The grader has three checks: `controller-running`, `status-current` and `statefulset-by-controller`. At the start, all three fail. Run the command after the repair and read the results.

---

## Step 1: Compare the two numbers

Print `metadata.generation` and the `observedGeneration` of the `Reconciled` condition:

```sh
kubectl -n starfleet get prometheus starfleet \
  -o jsonpath='generation={.metadata.generation} observed={.status.conditions[?(@.type=="Reconciled")].observedGeneration}{"\n"}'
```

The generation is higher than the observed generation. The conditions still say `True`, but they describe the `spec` from before the `logLevel` change. No check turns green in this step.

---

## Step 2: Look at the controller

A stale status means the controller has not acted on the latest change. Check the controller's Deployment:

```sh
kubectl -n default get deployment prometheus-operator
```

The Deployment is scaled to zero replicas, so no pod runs. This is why nothing built the new flag. The StatefulSet `prometheus-starfleet` has no `--log.level` flag yet.

---

## Step 3: Start the controller

Scale the Deployment back to one replica and wait for the rollout:

```sh
kubectl -n default scale deployment prometheus-operator --replicas=1
kubectl -n default rollout status deployment prometheus-operator --timeout=180s
```

The check `controller-running` passes. On start, the controller reconciles every `Prometheus` resource, so it acts on the `logLevel` change without a new event. Do not patch the StatefulSet yourself: the check `statefulset-by-controller` rejects a StatefulSet written with `kubectl`, and the controller would put the old value back.

---

## Step 4: Wait for the status to catch up

Wait for the conditions, then compare the numbers again:

```sh
kubectl -n starfleet wait --for=condition=Available --timeout=300s prometheus/starfleet
kubectl -n starfleet get prometheus starfleet \
  -o jsonpath='generation={.metadata.generation} observed={.status.conditions[?(@.type=="Reconciled")].observedGeneration}{"\n"}'
kubectl -n starfleet get statefulset prometheus-starfleet \
  -o jsonpath='{.spec.template.spec.containers[?(@.name=="prometheus")].args}{"\n"}'
```

The two numbers are equal and the container args contain `--log.level=debug`. The checks `status-current` and `statefulset-by-controller` pass.

---

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## If a check stays red

- **`status-current` fails with a generation message.** The `Prometheus` resource was deleted and created again, or the `logLevel` change was removed. Keep the original resource and the change.
- **`status-current` fails with `Available=False`.** The pod is still restarting after the StatefulSet changed. Wait a minute and submit again.
- **`statefulset-by-controller` fails with a `kubectl` message.** The StatefulSet was edited by hand. Scale the controller up and let it write the StatefulSet again; if the message stays, delete the StatefulSet and the controller creates it again.
- **`controller-running` fails.** The Deployment is still at zero replicas or its pod is not ready. Run `kubectl -n default get pods`.
