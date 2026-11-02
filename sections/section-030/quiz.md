# Section 030 Knowledge Check: Platform APIs With Crossplane

## Coverage

- Install Crossplane with Helm and confirm its pods and CRDs are healthy
- Install a provider package and read INSTALLED and HEALTHY from kubectl get providers
- Configure a ProviderConfig for provider-kubernetes that uses an injected identity, and grant it the RBAC it needs
- Create a managed resource directly and read its Synced and Ready conditions
- Diagnose a managed resource that is not Synced because of missing provider permissions
- Write a CompositeResourceDefinition in apiextensions.crossplane.io/v2 with a namespaced scope and a validated schema
- Install function-patch-and-transform and reference it from a Composition in Pipeline mode
- Compose several in-cluster resources (Namespace, ResourceQuota, Deployment, Service) from one composite resource
- Patch values from the composite resource spec into composed resources and write fields back to status
- Preview what a Composition will produce with crossplane composition render before applying it
- Request a composite resource in a tenant namespace and follow it to Ready
- Trace a composite resource to every composed and managed resource with crossplane resource trace
- Read Synced and Ready conditions on the composite resource and its composed resources to find the failing one
- Diagnose a Composition that references a missing function or patches a field that does not exist
- Choose between deleting a composite resource and orphaning its composed resources

## Questions

### Question 1

A `Provider` object for `provider-kubernetes` shows `INSTALLED True` and `HEALTHY False` in `kubectl get providers`. What does this tell you?

- A. The provider is running, but the ProviderConfig has the wrong credentials.
- B. The package manager unpacked the package and created its CRDs, but the provider pod is not running and ready.
- C. The package manager could not download the package from `xpkg.crossplane.io`.
- D. The provider is ready to create managed resources, because the CRDs exist.

**Answer:** B

**Explanation:** `INSTALLED` means the package manager downloaded the package and created its CRDs. `HEALTHY` means the provider pod runs and is ready. Neither column checks credentials, and a blocked download leaves `INSTALLED` unset.

### Question 2

Why does the course create a `DeploymentRuntimeConfig` with a `serviceAccountTemplate` before it installs `provider-kubernetes`?

- A. The ServiceAccount of a provider is needed so the provider can download its package.
- B. Without it, the provider cannot use the `InjectedIdentity` source.
- C. It grants the provider access to the objects it will manage.
- D. Crossplane otherwise generates the ServiceAccount name with a random suffix, and a fixed name makes the later RBAC binding simple.

**Answer:** D

**Explanation:** The `DeploymentRuntimeConfig` only sets options for the provider Deployment, here the ServiceAccount name. It grants no permissions. A fixed name lets a RoleBinding refer to the ServiceAccount.

### Question 3

A ProviderConfig for `provider-kubernetes` uses `credentials.source: InjectedIdentity`. Which statement is correct?

- A. The provider acts as the ServiceAccount of its own pod, so Kubernetes RBAC decides what it may do.
- B. The ProviderConfig grants the provider the permissions it needs in the cluster.
- C. The provider reads a kubeconfig from a Secret in `crossplane-system`.
- D. The provider uses the identity of the user who applied the managed resource.

**Answer:** A

**Explanation:** With `InjectedIdentity`, no secret is stored. The ProviderConfig only names the identity. It never changes RBAC. The `Secret` source is the one that reads a kubeconfig.

### Question 4

You run `kubectl auth can-i create services -n outpost --as=system:serviceaccount:crossplane-system:provider-kubernetes` right after installing the provider and its ProviderConfig. What is the result, and why?

- A. `yes`, because the provider is installed and healthy.
- B. `yes`, because the ProviderConfig names the injected identity.
- C. `no`, because the Crossplane RBAC manager gives a provider access only to its own CRDs and a few core kinds, not to Services.
- D. `no`, because the ProviderConfig is in the wrong namespace.

**Answer:** C

**Explanation:** Only you know which objects a provider must manage, so Crossplane does not grant that access. You add a Role and a RoleBinding.

### Question 5

An `Object` that wraps a Service shows `Synced False`, and the `Synced` message ends with a `forbidden` error for the ServiceAccount `system:serviceaccount:crossplane-system:provider-kubernetes`. What is the correct fix?

- A. Edit the manifest inside the `Object`, because it is invalid.
- B. Create a Role for `services` in `outpost` and bind it to that ServiceAccount.
- C. Bind `cluster-admin` to the provider ServiceAccount.
- D. Create the Service by hand so the provider only has to read it.

**Answer:** B

**Explanation:** The error comes from the API server, and the identity is the provider ServiceAccount, so the ProviderConfig worked. The missing permission is on `services` in `outpost`. Grant only that, in that namespace.

### Question 6

What is the difference between the `Synced` and `Ready` conditions on a managed resource?

- A. `Synced` says whether the provider could reconcile the resource. `Ready` says whether the external resource exists and is usable.
- B. `Synced` says the external resource is usable. `Ready` says the provider could connect.
- C. `Synced` is set by the tenant. `Ready` is set by Crossplane.
- D. They mean the same, and Crossplane sets both at the same time.

**Answer:** A

**Explanation:** A failed reconcile gives `Synced False`, and the message and events say why. `Ready` describes the external resource itself.

### Question 7

What happens to the Service when you run `kubectl -n outpost delete objects.kubernetes.m.crossplane.io scout` with the default settings?

- A. The Service stays, because the provider never deletes what it created.
- B. The Service stays until you delete it by hand.
- C. The provider deletes the Service before the `Object` disappears, because the default deletion policy is `Delete`.
- D. The `Object` stays until you delete the Service.

**Answer:** C

**Explanation:** Deleting the `Object` is the correct way to remove what it created. If you delete the Service by hand, the provider recreates it.

### Question 8

How does an XRD in Crossplane 2.x relate to a CRD, and what is the default scope?

- A. The XRD replaces the CRD, so no CRD exists in the cluster. The scope is `Cluster` by default.
- B. The XRD creates a CRD, and tenants must request through claims by default.
- C. The XRD is a plain CRD with a different `kind`. The scope is `Namespaced` only when you add claims.
- D. Crossplane creates a real CRD from the XRD schema. The XRD uses `apiextensions.crossplane.io/v2` and the scope is `Namespaced` by default.

**Answer:** D

**Explanation:** Claims exist only for `scope: LegacyCluster`. A namespaced composite resource lives in the tenant namespace and is created directly.

### Question 9

A `TeamEnvironment` with `spec.replicas: 9` is applied, and the XRD schema sets `maximum: 3` for `replicas`. What happens?

- A. The API server rejects the object, and nothing is stored, so no Composition can act on it.
- B. Crossplane accepts the object, and the Composition lowers the value to 3.
- C. The object is stored, and the XR reports `Synced False`.
- D. The object is stored, and the provider refuses to create the Deployment.

**Answer:** A

**Explanation:** The API server validates the composite resource with the OpenAPI v3 schema before Crossplane sees it.

### Question 10

Which Composition setup is correct in Crossplane 2.x?

- A. `mode: Resources`, with a list of base resources and patches under `spec.resources`.
- B. `mode: Pipeline`, with each step calling a composition function through `functionRef.name`.
- C. `mode: Pipeline`, with `functionRef.name` set to the package address of the function.
- D. No mode is needed, because Crossplane creates the resources itself.

**Answer:** B

**Explanation:** The old mode with a plain `resources:` list no longer exists. The `functionRef` name must equal the name of the installed `Function` object, not the package name.

### Question 11

A Composition has a patch with `type: FromCompositeFieldPath`, `fromFieldPath: spec.replicas` and `toFieldPath: spec.forProvider.manifest.spec.replicas`. What does it do, and which component applies the result in the cluster?

- A. It copies the Deployment replica count into the XR status. Crossplane then updates the Deployment.
- B. It copies the value into the XRD schema. The API server then updates the Deployment.
- C. It copies the value from the XR into the composed `Object` manifest. `provider-kubernetes` then updates the real Deployment.
- D. It copies the value into the XR, and the Deployment is changed by the function.

**Answer:** C

**Explanation:** `ToCompositeFieldPath` is the patch type for the other direction. A status value written that way is kept only when the XRD schema declares the field.

### Question 12

A `ToCompositeFieldPath` patch writes to `status.availableReplicas`, but the XRD schema does not declare that status field. What happens?

- A. The API server prunes the field, so it never shows on the XR.
- B. The field appears on the XR, because status is never validated.
- C. The XRD is rejected the next time it is applied.
- D. The provider creates the field on the Deployment.

**Answer:** A

**Explanation:** The XRD must declare every status field you want to keep.

### Question 13

What does `crossplane composition render xr.yaml composition-teamenvironment.yaml functions.yaml` do?

- A. It applies the Composition to the cluster and prints the composed resources.
- B. It checks that the provider has the RBAC it needs to create the resources.
- C. It prints the tree of an XR that already exists in the cluster.
- D. It runs the pipeline on your machine and prints the resources it would create, without changing the cluster.

**Answer:** D

**Explanation:** Render runs each function as a container, so it needs a container runtime and outbound internet. It shows the resources, not whether the provider can create them.

### Question 14

A composite resource stays not ready. `crossplane resource trace teamenvironment cache-env -n outpost -o wide` shows one `Object` row with `Synced False`. What is the best next step?

- A. Delete the `Object`, because the XR will fix itself.
- B. Describe that `Object` and read its conditions and events, which come from `provider-kubernetes`.
- C. Edit `spec.crossplane.resourceRefs` on the XR to remove the row.
- D. Re-apply the XR in the `default` namespace.

**Answer:** B

**Explanation:** The method has three steps: read the XR conditions, trace down to the row that is not ready, then read that object. Crossplane owns `resourceRefs`, so a manual change is overwritten.

### Question 15

A composite resource has `Synced False` with reason `ReconcileError`. The message names a function that is not installed. Where do you fix it?

- A. In the XR, by deleting the `spec.crossplane` block.
- B. In the ProviderConfig, by changing the credentials.
- C. In the Composition, by installing the function or by naming one that exists in `functionRef.name`.
- D. In the XRD, by lowering the schema version.

**Answer:** C

**Explanation:** When Crossplane cannot run the pipeline, it changes no composed objects. The API server accepts such a Composition, because it only checks the shape.

### Question 16

A tenant deletes a ready `TeamEnvironment` with `kubectl delete teamenvironment scout-env` and the default cascade. Which components remove the Deployment `scout`?

- A. The garbage collector deletes the composed `Object`, and then `provider-kubernetes` deletes the real Deployment.
- B. The garbage collector deletes the Deployment directly through an owner reference.
- C. Nothing deletes it, because the Deployment has no owner.
- D. The function deletes it when the pipeline runs a last time.

**Answer:** A

**Explanation:** The `Object` has the XR as owner, but the Deployment has no owner reference to the XR. The provider removes the Deployment after the `Object` goes.

### Question 17

A platform team must remove a `TeamEnvironment` but keep the running `scout` workload for another team. What do they run, and what is the result?

- A. `kubectl delete teamenvironment scout-env`. The workload stays, because the default cascade is orphan.
- B. `kubectl delete teamenvironment scout-env --cascade=orphan`. The `Object` resources and the workload stay, with no composite resource as owner.
- C. `kubectl delete teamenvironment scout-env --cascade=orphan`. The workload is deleted, but the `Object` resources stay.
- D. `kubectl delete objects --all`. The XR stays, and the workload stays.

**Answer:** B

**Explanation:** After an orphan delete, nothing updates the `Object` resources when the Composition changes, and the platform team owns the cleanup. Deleting an orphaned `Object` still deletes its real object.
