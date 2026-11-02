# Final Quiz: Platform APIs and Self-Service Capabilities

This quiz covers the whole domain. It has 24 questions: six on CustomResourceDefinitions (CRDs), six on operators, six on Crossplane and six on self-service provisioning workflows. Many questions follow one tenant request through the platform: the API server may refuse it, accept it and never make it ready, or block it with Role-Based Access Control (RBAC).

## Coverage

- Design a CRD schema, read how the API server validates, prunes and defaults, and use CEL rules, versions and subresources
- Read what a controller does through ownerReferences, conditions, observedGeneration, cascading deletion and finalizers
- Build a platform API with a CompositeResourceDefinition (XRD), a Composition pipeline and a provider, and trace a composite resource when it is not ready
- Run provisioning with Argo Workflows, Argo Events and Argo CD, and give tenants only the RBAC they need
- Find which component holds the fault when a request is refused, never becomes ready or is blocked

## Questions

Each question has one best answer. Think about the answer first, then read the explanation below it.

### Question 1

A tenant in `outpost` applies a `TeamEnvironment` with `size: huge`. The XRD schema allows only `small`, `medium` and `large` for `size`. What happens?

- A. The object is stored, and the Composition lowers `size` to `large`.
- B. The API server refuses the object with a schema error. Nothing is stored, so no Composition, workflow or provider acts on it.
- C. The object is stored with `Ready False`, and Crossplane reports the error in the conditions.
- D. The object is stored, and `provider-kubernetes` refuses to create the Deployment.

**Answer:** B

**Explanation:** The API server checks every write against the OpenAPI v3 schema before any controller sees the object. A refused request creates no object, so there is no status to read. The error is in the `kubectl` output.

### Question 2

A CRD has a structural schema with a declared `spec.replicas` field. A client without strict field validation (`kubectl apply --validate=false`) sends an object with the field `spec.replcas: 3`. What does the API server do?

- A. It refuses the object with a `strict decoding error`.
- B. It stores `replcas` exactly as written.
- C. It renames `replcas` to `replicas`.
- D. It prunes `replcas` without an error and stores the rest of the object.

**Answer:** D

**Explanation:** Pruning drops every field that the schema does not declare. The error appears only when the client asks for strict validation, which `kubectl` does by default. A schema with `x-kubernetes-preserve-unknown-fields: true` would keep the field.

### Question 3

A controller must write `status.phase` on a `TeamEnvironment` without changing `spec`. The CRD enables the `status` subresource. Which request does this?

- A. A request to the `/status` endpoint, for example `kubectl patch --subresource=status`.
- B. A normal `kubectl apply` of a manifest that contains `status.phase`.
- C. A `kubectl scale` request.
- D. A normal `kubectl edit` that changes `spec` and `status` together.

**Answer:** A

**Explanation:** With the subresource enabled, the normal endpoint ignores `status`. Only the `/status` endpoint changes it, and that endpoint ignores changes to `spec`. This keeps a tenant's `spec` update from overwriting what the controller reports.

### Question 4

A CRD serves `v1alpha1` and `v1`, and `v1` is the storage version. The CRD lists `v1alpha1` first. A user runs `kubectl get teamenvironments`, with no version in the resource name. Which version does the API server use?

- A. `v1alpha1`, because it is first in the CRD.
- B. The storage version only, because `kubectl get` reads from etcd.
- C. `v1`, because the group's preferred version comes from version priority, and `v1` ranks before `v1alpha1`.
- D. Both versions, with one table for each.

**Answer:** C

**Explanation:** The preferred version of a group follows version priority, not the order of the list in the CRD. A client that needs one exact version writes it in the resource name, for example `teamenvironments.v1alpha1.platform.starfleet.io`.

### Question 5

A CRD enables the `scale` subresource with `specReplicasPath: .spec.replicas`. A platform engineer runs `kubectl scale teamenvironment alpha --replicas=3`. What changes in the cluster?

- A. The API server creates three pods.
- B. The API server changes `status.readyReplicas` to 3.
- C. The API server writes `spec.replicas: 3`. A controller must still react and create the workload.
- D. The API server changes the Deployment that the object owns.

**Answer:** C

**Explanation:** The scale endpoint only reads and writes the fields named in the CRD, after a check against the schema. It runs no workload. The object is a request, and a controller or Composition turns the new count into running pods.

### Question 6

A CRD schema allows `replicas` up to 5. It also has this CEL rule on `spec`: `self.size != 'small' || self.replicas <= 2`. A user applies an object with `size: small` and `replicas: 4`. What does the user see?

- A. The API server passes the schema checks and then refuses the object because the CEL rule is false.
- B. The API server accepts the object, because `replicas` is below the schema maximum.
- C. The API server refuses the object with a schema error, and it skips the CEL rule.
- D. The API server changes `replicas` to 2.

**Answer:** A

**Explanation:** The schema allows 4, so the schema checks pass and the API server runs the CEL rule. The rule is false for this object, so the request is refused with the message of the rule. CEL rules are skipped only when the schema checks fail first.

### Question 7

A tenant deletes a `Prometheus` resource. The Prometheus Operator in this course adds no finalizer to it. Which component removes the StatefulSet that the operator created for it?

- A. The Prometheus Operator, which runs cleanup code during the delete request.
- B. The API server, which deletes every object in the same namespace.
- C. The StatefulSet controller, because the StatefulSet has no pods left.
- D. The garbage collector, which follows the `ownerReference` from the StatefulSet to the deleted `Prometheus` resource.

**Answer:** D

**Explanation:** The operator marks the `Prometheus` resource as the owner of the objects it creates. When the owner is gone, the garbage collector deletes the dependents. This works even if the operator is not running.

### Question 8

Which list shows the steps of a reconcile loop in the correct order?

- A. Write status, act on the difference, read actual state, read desired state.
- B. Read desired state, read actual state, act on the difference, write status.
- C. Act on the difference, read desired state, write status, read actual state.
- D. Read actual state, write status, read desired state, act on the difference.

**Answer:** B

**Explanation:** A controller compares what the custom resource asks for with what exists. It changes the cluster only where the two differ, and it reports the result in `status`. It repeats the cycle on every watch event.

### Question 9

A `TeamEnvironment` owns a ConfigMap through an `ownerReference`. An engineer deletes it with `kubectl delete teamenvironment alpha --cascade=foreground`. What is the order of events?

- A. The garbage collector deletes the dependent ConfigMap first, and the owner is removed after that.
- B. The owner is removed first, and the ConfigMap is removed later.
- C. The ConfigMap is orphaned, and only the owner is removed.
- D. Nothing is deleted until the engineer removes the ConfigMap by hand.

**Answer:** A

**Explanation:** Foreground deletion removes the dependents before the owner. Background deletion removes the owner first. Orphan deletion removes the owner and keeps the dependents.

### Question 10

An engineer runs `kubectl delete configmap scout-settings --wait=false`. The object stays. Which two fields of the object show why?

- A. `metadata.generation` and `status.conditions`.
- B. `metadata.labels` and `metadata.annotations`.
- C. `spec.replicas` and `status.phase`.
- D. `metadata.deletionTimestamp` and `metadata.finalizers`.

**Answer:** D

**Explanation:** The API server sets `deletionTimestamp` when it accepts the delete request. The object stays while `finalizers` still lists a name. The component that owns that name must do its cleanup and remove it. The next step is to find that component, not to remove the name by hand.

### Question 11

A tenant applies a custom resource that the API server accepts. Minutes later it has no `status.conditions`, no child objects and no events. Other custom resources of the same kind behave the same way. What is the most likely cause?

- A. The CRD schema is wrong, because the API server accepted the object.
- B. No controller is running, or it cannot start, so nothing acts on the object. Check the controller Deployment and its logs.
- C. The tenant needs the `edit` ClusterRole to see conditions.
- D. The garbage collector has not run yet.

**Answer:** B

**Explanation:** A CRD only adds a kind to the API server. A controller must read the objects, build the child objects and write conditions. When the status is empty for every object of the kind, check the controller first.

### Question 12

An administrator wants to test what the Prometheus Operator may do. Its pod runs in the namespace `default` with the ServiceAccount `prometheus-operator`. Which `--as` value does `kubectl auth can-i` need?

- A. `--as=prometheus-operator`
- B. `--as=serviceaccount:prometheus-operator:default`
- C. `--as=system:serviceaccount:default:prometheus-operator`
- D. `--as=system:node:default`

**Answer:** C

**Explanation:** The name of a ServiceAccount user is `system:serviceaccount:<namespace>:<name>`. The check uses the real RBAC rules, so it shows what the controller can do in the cluster. The same form works for any pod identity, such as a provider or a workflow.

### Question 13

A `TeamEnvironment` passes the schema and shows `SYNCED True` and `READY False`. `crossplane resource trace` shows one `Object` for a Service with `Synced False`. Its message ends with a `forbidden` error for `system:serviceaccount:crossplane-system:provider-kubernetes` on `services` in `outpost`. What is the correct fix?

- A. Edit the `TeamEnvironment` and remove the Service from `spec`.
- B. Bind `cluster-admin` to the ServiceAccount of the provider.
- C. Delete the `Object` and wait for the XR to fix itself.
- D. Create a Role for `services` in `outpost` and bind it to the provider ServiceAccount.

**Answer:** D

**Explanation:** The ProviderConfig worked, because the request reached the API server as the provider identity. The API server refused it for lack of RBAC. Grant only the verbs on the kind in that namespace. Option B works but gives a provider far more power than it needs.

### Question 14

A Composition pipeline step has `functionRef.name: function-patch-and-transform`. The XR shows `Synced False` with a `ReconcileError` that names a missing function. Which check finds the cause?

- A. Run `kubectl get functions` and compare the name of the installed `Function` object with `functionRef.name`.
- B. Run `kubectl get providers` and read the `HEALTHY` column.
- C. Run `kubectl get crd` and look for the XRD.
- D. Run `kubectl auth can-i` for the tenant.

**Answer:** A

**Explanation:** The `functionRef.name` must equal the name of the installed `Function` object, not the package address. The API server accepts a Composition that names a missing function, because it checks only the shape. The error appears when Crossplane runs the pipeline.

### Question 15

An engineer wants to see what a Composition would create, before applying it to the cluster. The command `crossplane composition render` fails on a laptop that has no container runtime. Why does it need one?

- A. The command installs the provider on the laptop.
- B. The command runs each composition function as a container on the laptop, and the function image comes from a registry.
- C. The command applies the XRD to a local cluster.
- D. The command checks the RBAC of the provider.

**Answer:** B

**Explanation:** Render runs the pipeline locally and prints the resources it would create. It does not change the cluster. It also does not show whether the provider has permission to create them.

### Question 16

A composite resource is not ready. Which order of checks follows a sound method?

- A. Delete the composed objects, apply the XR again, then read the provider log.
- B. Edit `resourceRefs` on the XR, then describe the Composition, then read the Application.
- C. Read the conditions of the XR, trace down to the row that is not ready, then describe that object and read its conditions and events.
- D. Restart Crossplane, then restart the provider, then read the XR.

**Answer:** C

**Explanation:** Each step narrows the search to the component that holds the fault. Crossplane owns `resourceRefs`, so a manual change is overwritten. A restart removes the evidence that the conditions and events hold.

### Question 17

A platform team wants tenants to request a `TeamEnvironment` directly in their own namespace, with no claim object. What does the team define?

- A. An XRD in `apiextensions.crossplane.io/v2` with `scope: Namespaced`.
- B. An XRD with `scope: LegacyCluster` and a claim kind.
- C. A plain CRD, because an XRD cannot be namespaced.
- D. A Composition with `mode: Resources`.

**Answer:** A

**Explanation:** In Crossplane 2.x a composite resource is namespaced by default, and a tenant creates it directly. Claims exist only for `scope: LegacyCluster`. The Composition still uses `mode: Pipeline`.

### Question 18

A managed resource shows `Synced True` and `Ready False`. What does this tell you?

- A. The provider could not connect to the cluster.
- B. The tenant has no permission to read the object.
- C. The Composition refers to a missing function.
- D. The provider reconciled the resource without an error, but the external resource is not yet usable.

**Answer:** D

**Explanation:** `Synced` says whether the provider could reconcile the resource. `Ready` says whether the external resource exists and is usable. A failed reconcile gives `Synced False`, and its message says why.

### Question 19

A Workflow ends as `Failed`. What is the best order to find the cause?

- A. Read the log of the workflow controller, then restart it.
- B. Delete the Workflow and submit it again, then compare the result.
- C. Read the phase of the Workflow, find the failed node and its message, then read the log of the `main` container of that step.
- D. Read the EventBus, then the Sensor, then the EventSource.

**Answer:** C

**Explanation:** The Workflow status lists every node with its own phase and message. The failed node names the step to read. The `main` log of that pod then shows the real error, for example a `forbidden` message from the API server.

### Question 20

What does an EventBus do in Argo Events?

- A. It receives the HTTP request from the client and returns the `200`.
- B. It carries the events that EventSources publish to the Sensors in the same namespace.
- C. It creates the Workflow from the event.
- D. It filters events with a data filter.

**Answer:** B

**Explanation:** The EventSource receives the request and publishes the event. The Sensor reads it from the EventBus, applies its filter and runs the trigger. Without an EventBus, the EventSource and the Sensor cannot pass events.

### Question 21

A tenant in the group `outpost-team` can create and read `teamenvironments` in `outpost`. The same tenant runs `kubectl -n outpost create deployment web --image=nginx` and gets `forbidden`. How should the platform team read this?

- A. As a fault. The platform team must add `create` on `deployments` to the Role.
- B. As a fault in the AppProject, because it blocks Deployments.
- C. As a fault in the Composition, because it should have created the Deployment for the tenant.
- D. As the correct result. The Role allows only the platform API kind. The Composition and the provider create the Deployment with their own identities.

**Answer:** D

**Explanation:** A tenant that asks only for a `TeamEnvironment` needs no rights on Deployments or Secrets. The proof has two parts: `kubectl auth can-i create teamenvironments.platform.starfleet.io` is `yes`, and `create deployments.apps` is `no`. Giving the tenant the built-in `edit` ClusterRole would also let it read Secrets.

### Question 22

The platform team creates a ClusterRole with the label `rbac.authorization.k8s.io/aggregate-to-view: "true"` and a rule that allows `get`, `list` and `watch` on `teamenvironments`. Who gets read access to `teamenvironments` without a new binding?

- A. Only the members of the group `outpost-team`.
- B. Every user in the cluster.
- C. Every subject that already holds the built-in `view` ClusterRole, because the control plane copies the rules into it.
- D. Nobody, because a built-in ClusterRole cannot receive new rules.

**Answer:** C

**Explanation:** The built-in `view` ClusterRole is an aggregated role. A controller in the control plane adds the rules of every ClusterRole that carries its label. Use this to extend built-in roles for the platform's own users.

### Question 23

A tenant commits a `TeamEnvironment` file with `metadata.namespace: starfleet`. The Argo CD `AppProject` of the tenant allows only the destination namespace `outpost`. What happens when Argo CD syncs the Application?

- A. Argo CD applies the object in `starfleet`, because the repository is allowed.
- B. Argo CD refuses the object because the destination is not allowed. The reason shows in the Application conditions, and no object is created.
- C. Argo CD applies the object in `outpost` instead.
- D. Argo CD creates the object and Crossplane refuses to compose it.

**Answer:** B

**Explanation:** An AppProject limits the repositories, destination namespaces and resource kinds of its Applications. A request file therefore cannot give itself more reach than the project allows. Read the Application first when the object does not exist.

### Question 24

A tenant commits a `TeamEnvironment` file to Git. Which order describes how the request becomes a ready environment?

- A. Argo CD syncs the file. The API server validates it against the schema. Crossplane runs the Composition and creates the composed objects. The XR reports `Ready True`.
- B. Crossplane reads the file from Git. Argo CD runs the Composition. The API server creates the objects.
- C. The API server reads the file from Git. Argo CD validates the schema. The Sensor runs the Composition.
- D. Argo CD runs the Composition. Crossplane syncs the file. The XR reports `Ready True` before any object exists.

**Answer:** A

**Explanation:** Each component has one job. Argo CD only applies what is in Git. The API server accepts or refuses the object. Crossplane builds the environment. A request can stop at any step: refused by the schema, blocked by the project or by RBAC, or accepted and never `Ready`. The `Synced` status of the Application proves only that the file reached the cluster.
