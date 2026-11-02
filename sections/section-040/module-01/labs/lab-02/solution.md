---
estimated_duration: 25m
---

# Solution

The workflow fails because the step pods run as `provisioner`, and `provisioner` has too few permissions in `outpost`. You read the failure, then fix the Role and the RoleBinding in `outpost`. The WorkflowTemplate stays as it is.

| Goal | Where it lives | Object |
| --- | --- | --- |
| Identity of the step pods | `serviceAccountName` in the WorkflowTemplate | ServiceAccount `provisioner` in `starfleet` |
| Permissions in `outpost` | the namespace of the target objects | Role and RoleBinding in `outpost` |
| Who receives the Role | `subjects` of the RoleBinding | the ServiceAccount with its own namespace, `starfleet` |
| Proof of the fix | the API server | `kubectl auth can-i --as=system:serviceaccount:starfleet:provisioner` |

## Step 1: Submit a Workflow and read the failure

Submit a Workflow from the template. Save this as `workflow-deploy-scout.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: deploy-scout-
  namespace: starfleet
spec:
  serviceAccountName: provisioner
  workflowTemplateRef:
    name: deploy-scout
```

Create it and read the phase:

```bash
kubectl create -f workflow-deploy-scout.yaml
kubectl -n starfleet get workflows
```

The Workflow ends as `Failed`. Nothing is graded yet. Read the nodes of the newest Workflow to find the step that failed:

```bash
kubectl -n starfleet get workflows -o jsonpath='{range .items[-1].status.nodes.*}{.displayName}{"\t"}{.phase}{"\t"}{.message}{"\n"}{end}'
```

The node `scout-deployment` has the phase `Failed`. The node `scout-service` does not start, because the first step failed. Read the log of the failed step. Replace `<name>` with the name of the newest Workflow:

```bash
kubectl -n starfleet logs -l workflows.argoproj.io/workflow=<name> -c main
```

The log contains an error from the API server with the word `forbidden`. It names `system:serviceaccount:starfleet:provisioner`, the verb, the resource and the namespace `outpost`. That line tells you who was refused, what it tried and where.

## Step 2: Ask the API server what provisioner may do

Test the permissions before you change anything:

```bash
kubectl auth can-i create deployments.apps -n outpost --as=system:serviceaccount:starfleet:provisioner
kubectl auth can-i create services -n outpost --as=system:serviceaccount:starfleet:provisioner
```

Both answers are `no`. A Role named `provisioner-scout` exists in `outpost`. Read it and its RoleBinding:

```bash
kubectl -n outpost get role provisioner-scout -o yaml
kubectl -n outpost get rolebinding provisioner-scout -o yaml
```

There are two faults. The Role has a rule for `deployments` but none for `services`. The RoleBinding names the ServiceAccount `provisioner` in the namespace `outpost`, but the ServiceAccount lives in `starfleet`.

## Step 3: Fix the Role and the RoleBinding

A resource step with `action: apply` reads, creates and patches the object, so the verbs are `get`, `create` and `patch`. Save this as `role-provisioner-outpost.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: provisioner-scout
  namespace: outpost
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "create", "patch"]
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get", "create", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: provisioner-scout
  namespace: outpost
subjects:
  - kind: ServiceAccount
    name: provisioner
    namespace: starfleet
roleRef:
  kind: Role
  name: provisioner-scout
  apiGroup: rbac.authorization.k8s.io
```

What changed:

* The second rule adds `services` in the core API group, written as `""`.
* The subject now has `namespace: starfleet`, the namespace of the ServiceAccount. The `roleRef` is unchanged, because a RoleBinding cannot change its `roleRef`.

Apply it and test again:

```bash
kubectl apply -f role-provisioner-outpost.yaml
kubectl auth can-i create deployments.apps -n outpost --as=system:serviceaccount:starfleet:provisioner
kubectl auth can-i create services -n outpost --as=system:serviceaccount:starfleet:provisioner
kubectl auth can-i delete deployments.apps -n outpost --as=system:serviceaccount:starfleet:provisioner
```

The first two answers are `yes`. The third is `no`. The checks `verify-template-unchanged` and `verify-least-privilege` pass now.

## Step 4: Run the workflow again

Submit a new Workflow with the same file and read the result:

```bash
kubectl create -f workflow-deploy-scout.yaml
kubectl -n starfleet get workflows
kubectl -n outpost get deployment,service scout
```

The newest Workflow ends as `Succeeded`, and the Deployment and the Service `scout` exist in `outpost`. The check `verify-workflow-succeeds` passes now.

## Step 5: Submit

```bash
astrona submit -c sections/section-040/module-01/labs/lab-02
```

All three checks pass.

## If a check stays red

* **`verify-least-privilege` says provisioner cannot create in outpost.** The RoleBinding subject has the wrong namespace, or the Role lacks the rule for `services`. Run the `kubectl auth can-i` commands from step 2 to see which one.
* **`verify-least-privilege` says provisioner can do everything.** You bound `cluster-admin` or used `*`. Delete that binding and grant only `get`, `create` and `patch` on `deployments` and `services`.
* **`verify-least-privilege` says provisioner can delete.** Remove `delete` from the verbs. A resource step with `action: apply` does not need it.
* **`verify-least-privilege` says provisioner can create Deployments in `default` or `starfleet`.** The permission was granted with a ClusterRole or in the wrong namespace. The Role belongs in `outpost`.
* **`verify-template-unchanged` fails.** You changed `deploy-scout` or its ServiceAccount. Restore it: it must run as `provisioner` and keep both resource steps.
* **`verify-workflow-succeeds` reports a failed node.** Read the node message and the `main` log in the grader output. A `forbidden` line names the verb and the resource that is still missing.
