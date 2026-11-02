# Section 010 Knowledge Check: Extending The Kubernetes API With CRDs

## Coverage


- Write a CustomResourceDefinition in apiextensions.k8s.io/v1 with a structural openAPIV3Schema for a platform service
- Mark fields as required and constrain them with enum, minimum, maximum and pattern
- Set default values and predict which unknown fields the API server prunes
- Write a CEL rule in x-kubernetes-validations, including a transition rule that uses oldSelf
- Add additionalPrinterColumns and a shortName so kubectl get shows the important fields
- Prove a rule works by applying a custom resource the API server must reject
- Add a second version to a CRD and choose which version is served and which is the storage version
- Read which version an object is stored in from status.storedVersions
- Mark a version deprecated and read the warning kubectl prints
- Enable the status subresource and show that a spec update cannot change status
- Enable the scale subresource and scale a custom resource with kubectl scale

---

## Questions

### Question 1

A CRD has `spec` as an object with `x-kubernetes-preserve-unknown-fields: true` and no `properties`. A user applies a `TeamEnvironment` with the field `replcas: 3` instead of `replicas`. What happens?

A. The API server prunes `replcas` and stores the object
B. The API server refuses the object because the field is unknown
C. The API server stores `replcas` exactly as written and reports nothing
D. The API server renames `replcas` to `replicas`

**Answer:** C

**Explanation:** The schema describes nothing under `spec` and keeps unknown fields, so nothing is pruned or checked. A controller that reads `spec.replicas` finds nothing.

### Question 2

In which order does the API server process a create request for a custom resource?

A. Schema validation, pruning, defaulting, CEL rules
B. Defaulting, CEL rules, pruning, schema validation
C. CEL rules, schema validation, defaulting, pruning
D. Pruning, defaulting, schema validation, CEL rules

**Answer:** D

**Explanation:** The API server decodes the request, prunes unknown fields, fills defaults, checks the schema, runs the CEL rules, then runs admission webhooks. Defaults exist before validation runs, so a rule can read a defaulted field.

### Question 3

A `spec` has `required: [team, size, contact]`, and `replicas` has `default: 1` and `maximum: 5`. A user applies an object that leaves out `replicas`. Which result is correct?

A. The API server stores the object with `replicas: 1`
B. The API server rejects the object with `spec.replicas: Required value`
C. The API server stores the object without `replicas`
D. The API server stores the object with `replicas: 5`

**Answer:** A

**Explanation:** A field that is not in `required` and has a `default` receives that default before validation. Every reader of the object, including a controller, sees `replicas: 1`.

### Question 4

`kubectl apply` sends an object with an unknown field `spec.replcas` to a CRD with a structural schema. What does the user see?

A. The object is created and `replcas` is dropped silently
B. The object is created and `replcas` is stored
C. An error: `spec.replcas: Required value`
D. An error: `strict decoding error: unknown field "spec.replcas"`

**Answer:** D

**Explanation:** `kubectl` asks for strict field validation, so the API server refuses unknown fields. A client without strict validation (or `kubectl apply --validate=false`) gets silent pruning instead.

### Question 5

A CRD schema is made stricter: `size` must now be one of `small`, `medium`, `large`. An object already stored has `size: huge`. What happens when a user changes only `spec.contact` on that object to a valid value?

A. The update is refused, because the stored object is invalid
B. The update is accepted, because validation ratcheting allows an unchanged invalid value
C. The API server changes `size` to `small`
D. The API server deletes the object

**Answer:** B

**Explanation:** Validation ratcheting lets an update keep a value that is already invalid, as long as the value does not change. A change to another invalid value is still refused.

### Question 6

Which CEL rule on `spec` makes a `small` environment run at most 2 replicas?

A. `self.size == 'small' && self.replicas <= 2`
B. `self.replicas <= 2`
C. `self.size != 'small' || self.replicas <= 2`
D. `oldSelf.size != 'small' || oldSelf.replicas <= 2`

**Answer:** C

**Explanation:** The rule must be true for every valid object. It is true when the size is not small, or when there are at most 2 replicas. The option `self.size == 'small' && ...` would refuse every medium and large environment. The option with `oldSelf` is a transition rule that does not run on create.

### Question 7

A field `team` has the rule `self == oldSelf`. Which statement is correct?

A. The rule runs only on update, so the field cannot be changed after creation
B. The rule runs on create and update, and it blocks both
C. The rule runs only on create, so the field must equal its default
D. The rule runs only when the field is missing

**Answer:** A

**Explanation:** A rule that uses `oldSelf` is a transition rule. It is skipped on create, because there is no old value, and it refuses any update that changes the field.

### Question 8

A dry run with `kubectl apply --dry-run=server` of an object with `size: huge` prints schema errors and ends with `some validation rules were not checked because the object was invalid`. What does the last line mean?

A. The CEL rules passed
B. The CRD has a syntax error in a CEL rule
C. The object was stored anyway
D. The API server skipped the CEL rules because the schema checks already failed

**Answer:** D

**Explanation:** When schema validation fails, the API server skips CEL rules. Fix the schema errors first, then run the dry run again to see the CEL result.

### Question 9

The CRD lists three entries in `additionalPrinterColumns`, none of them for age. What does `kubectl get` show?

A. The three columns and an automatic `Age` column
B. The three columns only, with no `Age` column
C. Only `NAME` and `Age`
D. The three columns, and `Age` only with `-o wide`

**Answer:** B

**Explanation:** Once a CRD lists `additionalPrinterColumns`, the API server stops adding `Age`. The CRD must add it back with `type: date` and `jsonPath: .metadata.creationTimestamp`.

### Question 10

A CRD has `shortNames: [teamenv]` and `categories: [platform]`. Which statement is correct?

A. `kubectl get teamenv` works, and `kubectl get platform` fails
B. `kubectl get all` now lists the custom resources
C. `kubectl get teamenv` and `kubectl get platform` both work
D. `kubectl get platform` works only with `-o wide`

**Answer:** C

**Explanation:** A short name is another name for the type. A category lists every type in that category with one command. The type is not in `all` unless the CRD adds it. Adding custom types to `all` changes what `kubectl get all` returns for everyone, so avoid it.

### Question 11

A CRD lists version `v1alpha1` with `served: true, storage: false` and version `v1` with `served: true, storage: true`. A client writes an object through `v1alpha1`. How does the API server store it?

A. As `v1alpha1`, because the client used that version
B. As both versions in etcd
C. The API server refuses the write, because `v1alpha1` is not the storage version
D. As `v1`, because it is the storage version

**Answer:** D

**Explanation:** A served version is a version clients may use. The storage version is the one version the API server writes to etcd. With `strategy: None`, the API server changes only the `apiVersion` field.

### Question 12

A CRD stored objects as `v1alpha1`. An administrator makes `v1` the storage version. What does `status.storedVersions` show, and why?

A. `["v1alpha1","v1"]`, because old objects may still be stored as `v1alpha1`
B. `["v1"]`, because the API server rewrites every object at once
C. `["v1alpha1"]`, because the list changes only after a restart
D. `[]`, because the list is empty until an object is read

**Answer:** A

**Explanation:** The API server adds the new storage version to the list at once and never removes an old entry. To remove `v1alpha1`, rewrite every object, then patch the CRD status.

### Question 13

A CRD marks `v1alpha1` with `deprecated: true` and a `deprecationWarning`. A user reads an object through `v1alpha1`, and then the CRD is changed to `served: false` for `v1alpha1`. What does the user get in each case?

A. First a `NotFound` error, then a warning
B. First a warning and a successful read, then a `NotFound` error
C. A warning in both cases
D. A successful read in both cases, with no warning

**Answer:** B

**Explanation:** A deprecated version still works and `kubectl` prints the warning on standard error. After `served: false` the API server has no endpoint for that version, so it answers `NotFound`. The objects still exist.

### Question 14

The `status` subresource is enabled. A user runs `kubectl apply` with a manifest that sets `status.phase: Ready`. What happens to `status`?

A. The API server stores it
B. The API server rejects the request
C. The API server stores it only if `spec` is unchanged
D. The API server ignores `status` on the normal endpoint

**Answer:** D

**Explanation:** With the subresource enabled, the normal endpoint ignores `status`, and only requests to `/status` change it, for example `kubectl patch --subresource=status`. A request to `/status` also ignores changes to `spec`.

### Question 15

A CRD sets `scale` with `specReplicasPath: .spec.replicas` and `statusReplicasPath: .status.readyReplicas`. A user runs `kubectl scale teamenvironment alpha --replicas=9`, and the schema has `maximum: 5` on `spec.replicas`. What happens?

A. The API server sets `spec.replicas` to 9
B. The API server sets `spec.replicas` to 5
C. The API server refuses the request with a schema error and `spec.replicas` stays as it was
D. The API server sets `status.readyReplicas` to 9

**Answer:** C

**Explanation:** `kubectl scale` writes the desired count through the scale endpoint, and the API server checks the result against the CRD schema. `kubectl scale` never writes `status`, and the scale endpoint creates no pods.
