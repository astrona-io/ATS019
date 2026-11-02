# Section 020 Knowledge Check: Platform Automation With Operators

Each question has one best answer. Think about the answer first, then read the explanation below it.

## Coverage

- Name the controller, CRDs and RBAC objects an operator installs, from the cluster
- Trace a custom resource to the objects its controller created through ownerReferences
- Read status.conditions and compare observedGeneration with metadata.generation to judge whether the controller has acted
- Find why a reconcile failed from conditions, events and the controller's logs
- Show that the controller restores an owned object that was changed or deleted by hand
- Predict which dependent objects the garbage collector deletes when an owner is deleted
- Choose between foreground, background and orphan cascading deletion with kubectl delete --cascade
- Explain why an object with a finalizer stays in Terminating and which controller must remove the finalizer
- Diagnose an object stuck in Terminating and fix the cause instead of removing the finalizer by hand

---

## Questions

### Question 1

A cluster has the CustomResourceDefinition (CRD) `prometheuses.monitoring.coreos.com`. A user applies a `Prometheus` object, and the API server accepts it. The `prometheus-operator` Deployment has been deleted. What happens?

- A. The API server stores the object, but no Prometheus server starts.
- B. The API server rejects the object because no controller is running.
- C. The API server starts a Prometheus pod from the CRD schema.
- D. The object is stored and the StatefulSet controller of Kubernetes builds the Prometheus server.

**Answer:** A

**Explanation:** A CRD only adds a kind to the API server, which stores and validates the objects. The controller in the operator's Deployment reads the `Prometheus` object and builds the StatefulSet, Service and Secrets. Without it, nothing acts on the object.

### Question 2

An administrator wants to know which identity the Prometheus Operator controller uses to call the API server. Which command reads the answer?

- A. `kubectl api-resources --api-group=monitoring.coreos.com`
- B. `kubectl -n default get deployment prometheus-operator -o jsonpath='{.spec.template.spec.serviceAccountName}'`
- C. `kubectl -n starfleet get prometheus`
- D. `kubectl get clusterrole prometheus-operator`

**Answer:** B

**Explanation:** The controller sends every request as the ServiceAccount of its pod, and the Deployment's pod template names it. Option A lists the kinds the operator adds. Option C lists custom resources. Option D shows permissions but not which identity holds them.

### Question 3

You run these two commands on a cluster with the Prometheus Operator installed:

```sh
kubectl auth can-i create statefulsets -n starfleet --as=system:serviceaccount:default:prometheus-operator
kubectl auth can-i create deployments -n starfleet --as=system:serviceaccount:default:prometheus-operator
```

The first prints `yes` and the second prints `no`. What does this tell you?

- A. The operator is broken because it cannot create Deployments.
- B. The operator builds StatefulSets for a `Prometheus` resource, not Deployments.
- C. The ClusterRoleBinding for the operator is missing.
- D. The operator can create Deployments in other namespaces only.

**Answer:** B

**Explanation:** The ClusterRole of the operator lists `statefulsets` with `create`, and it does not list `deployments`. That matches how the operator works: one `Prometheus` resource becomes a StatefulSet. A missing binding would make both answers `no`.

### Question 4

A `Prometheus` resource named `starfleet` exists in namespace `starfleet`. You find the pod `prometheus-starfleet-0`. Which statement about its owner is correct?

- A. The pod has an `ownerReference` to the `Prometheus` resource `starfleet`.
- B. The pod has no `ownerReference`, because the operator creates it directly.
- C. The pod has an `ownerReference` to the StatefulSet `prometheus-starfleet`, and the StatefulSet has one to the `Prometheus` resource.
- D. The pod has an `ownerReference` to the `prometheus-operator` Deployment.

**Answer:** C

**Explanation:** Two controllers share the work. The Prometheus Operator creates the StatefulSet and marks the `Prometheus` resource as its owner. The built-in StatefulSet controller creates the pod and marks the StatefulSet as its owner.

### Question 5

An engineer runs `kubectl -n starfleet scale statefulset prometheus-starfleet --replicas=0` to stop a Prometheus server. A few seconds later, `spec.replicas` of the StatefulSet is `1` again. Which component changed it, and where should the engineer make the change instead?

- A. The StatefulSet controller changed it; the engineer should edit the pod.
- B. The Prometheus Operator changed it at its next reconcile; the engineer should change `spec.replicas` of the `Prometheus` resource.
- C. The API server rejected the change; the engineer should use `kubectl patch`.
- D. The garbage collector changed it; the engineer should remove the `ownerReference`.

**Answer:** B

**Explanation:** The operator watches the objects it owns. A change to one is a watch event, so it runs a reconcile and sets the StatefulSet back to what the `Prometheus` resource asks for. The desired state lives in the custom resource, so the fix goes there.

### Question 6

A `Prometheus` resource shows `generation=3` in `metadata` and `observedGeneration=2` in its `Reconciled` condition, which has `status: "True"`. What is the best conclusion?

- A. The status is current, because `Reconciled` is `True`.
- B. The `spec` was changed after the controller last acted, so the status describes an older `spec`.
- C. Someone changed a label, which raises `generation`.
- D. The controller wrote an invalid condition, and the API server will reject it.

**Answer:** B

**Explanation:** The generation counts `spec` changes, and `observedGeneration` is the generation the controller last acted on. When it is lower, the controller has not acted on the latest change, for example because it is not running. Labels and annotations do not raise `generation`.

### Question 7

You scale the `prometheus-operator` Deployment to zero replicas and change `spec.logLevel` of a `Prometheus` resource. Later you scale the Deployment back to one replica. What happens to the resource?

- A. The change is lost, because the controller missed the watch event.
- B. The change stays pending until you edit the resource a second time.
- C. The StatefulSet is deleted and created again by the garbage collector.
- D. The controller reads every `Prometheus` resource at startup, applies the change, and `observedGeneration` catches up to `generation`.

**Answer:** D

**Explanation:** A reconcile reads the whole desired state each time, not only the last change. After it starts, the controller reconciles every resource it finds and writes new conditions. The StatefulSet then carries the new flag.

### Question 8

A `Prometheus` resource reports `Reconciled True` and `Available False` with reason `NoPodReady` and an empty message. The controller runs. Where should you look next for the cause?

- A. The events on the owned StatefulSet, because the operator built its objects and something further down failed.
- B. The `Reconciled` message, because it always holds the cause.
- C. The CRD schema of `Prometheus`.
- D. The ClusterRoleBinding of the operator.

**Answer:** A

**Explanation:** `Reconciled True` means the operator built its objects without an error. Pods are created by the StatefulSet controller, which records an event such as `FailedCreate` on the StatefulSet. In the course example, the event said that the ServiceAccount `prometheus-reader` was not found.

### Question 9

A `Prometheus` resource reports `Reconciled False` with reason `ReconciliationFailed` and the message `creating config failed: loading additional scrape configs from Secret failed: secrets "extra-scrape" not found`. What is the correct fix?

- A. Delete the StatefulSet so the operator creates it again.
- B. Edit the generated Secret `prometheus-broken` by hand.
- C. Create the Secret `extra-scrape` that the resource references, and let the operator reconcile again.
- D. Remove the `ownerReference` from the StatefulSet.

**Answer:** C

**Explanation:** The operator itself could not finish, because the Secret that the custom resource references is missing. Fix the cause where it lives. The operator watches Secrets, so creating the Secret starts a new reconcile that succeeds.

### Question 10

The `TeamEnvironment` object `scout-env` has two ConfigMaps in its namespace. Both carry the label `team: outpost`. Only `scout-owned` has an `ownerReference` with the `uid` of `scout-env`. You delete `scout-env` with `--cascade=background`. Which ConfigMaps does the garbage collector delete?

- A. Both, because they share a label.
- B. Neither, because no controller manages `TeamEnvironment`.
- C. Only `scout-unowned`.
- D. Only `scout-owned`.

**Answer:** D

**Explanation:** The garbage collector uses owner references, not labels. It does not need a controller for the owner's kind. The ConfigMap without an owner reference stays.

### Question 11

An owner `probe-env` is deleted and created again with the same name. A dependent ConfigMap still holds the `uid` that `probe-env` had before. What does the garbage collector do with the ConfigMap?

- A. It keeps the ConfigMap, because the name matches.
- B. It treats the ConfigMap as a dependent of an owner that no longer exists, because the new object has a new `uid`.
- C. It updates the `uid` in the ConfigMap to the new value.
- D. It blocks the creation of the new owner.

**Answer:** B

**Explanation:** An owner reference identifies the owner by its `uid`, not by its name alone. A new object with the same name has a new `uid`, so the old reference points to an owner that is gone. Update the reference when you recreate the owner.

### Question 12

A platform team must remove a `TeamEnvironment` but keep its ConfigMap for a planned handover to another team. Which command does this, and what is the result?

- A. `kubectl delete teamenvironment probe-env --cascade=foreground`; the ConfigMap is deleted first.
- B. `kubectl delete teamenvironment probe-env --wait=false`; the ConfigMap is kept.
- C. `kubectl delete teamenvironment probe-env --cascade=orphan`; the ConfigMap stays and loses its reference to the deleted owner.
- D. `kubectl delete teamenvironment probe-env --cascade=background`; the ConfigMap stays because deletion is asynchronous.

**Answer:** C

**Explanation:** Orphan deletion keeps the dependents and removes this owner's reference from them. Option A deletes the blocking dependents before the owner goes. Option B only changes whether the client waits. Option D lets the garbage collector delete the dependents later.

### Question 13

A ConfigMap has the finalizer `platform.starfleet.io/cleanup`. You run `kubectl delete configmap scout-settings --wait=false`, and the command prints `deleted`. A minute later `kubectl get configmap scout-settings` still returns the object. What does this show?

- A. The delete request failed and must be sent again.
- B. The API server accepted the request and set `metadata.deletionTimestamp`. The object stays until the component that owns the finalizer removes its name.
- C. The API server runs the cleanup code named in the finalizer and is slow.
- D. The garbage collector is waiting for an owner reference.

**Answer:** B

**Explanation:** The word `deleted` means the request was accepted. The API server does not know what the finalizer name means and runs no code for it. The responsible component must notice the deletion timestamp, do its cleanup, and remove its own finalizer. A ConfigMap table has no `STATUS` column, so read `metadata.deletionTimestamp` and `metadata.finalizers`.

### Question 14

A ConfigMap is stuck with a deletion timestamp and the finalizer `platform.starfleet.io/cleanup`. The cleanup Job that implements this finalizer is suspended. The ServiceAccount of the Job already has the permissions it needs. What is the correct fix?

- A. Patch the ConfigMap and remove the finalizer from your terminal.
- B. Restart the `prometheus-operator` Deployment.
- C. Give the Job's ServiceAccount the `cluster-admin` ClusterRole.
- D. Set `suspend: false` on the Job, so the worker deletes the cache and then removes its own finalizer.

**Answer:** D

**Explanation:** The cause is that the responsible worker does not run. Starting it keeps the cleanup order: observe the deletion, delete the cache, then release the finalizer. Option A skips the cleanup the finalizer protects. Option B restarts an unrelated component. Option C is not needed, because the permissions are present.
