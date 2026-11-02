---
estimated_duration: 30m
---

# Solution

A normal create step ends when the object exists. A step with a `successCondition` keeps watching the object until the condition is true. That needs two things: a template with the conditions, and read permissions (`get`, `list`, `watch`) for the ServiceAccount, because watching is reading.

| Goal | Where it lives | Object |
| --- | --- | --- |
| Create the object | `resource.action: create` | resource step in the WorkflowTemplate |
| Wait for Ready | `successCondition` and `failureCondition` | same resource step |
| Identity of the step pod | `serviceAccountName` | ServiceAccount `provisioner` in `starfleet` |
| Permissions in `outpost` | Role and RoleBinding | `get`, `list`, `watch`, `create` on `teamenvironments` |

## Step 1: Give provisioner the permissions

Save this as `role-provisioner-teamenvironment.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: provisioner-teamenvironment
  namespace: outpost
rules:
  - apiGroups: ["platform.starfleet.io"]
    resources: ["teamenvironments"]
    verbs: ["get", "list", "watch", "create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: provisioner-teamenvironment
  namespace: outpost
subjects:
  - kind: ServiceAccount
    name: provisioner
    namespace: starfleet
roleRef:
  kind: Role
  name: provisioner-teamenvironment
  apiGroup: rbac.authorization.k8s.io
```

Apply it:

```bash
kubectl apply -f role-provisioner-teamenvironment.yaml
```

Then check the result:

```bash
kubectl auth can-i watch teamenvironments.platform.starfleet.io -n outpost --as=system:serviceaccount:starfleet:provisioner
kubectl auth can-i delete teamenvironments.platform.starfleet.io -n outpost --as=system:serviceaccount:starfleet:provisioner
```

The first command prints `yes` and the second prints `no`. The permissions check of the grader passes now.

## Step 2: Create the WorkflowTemplate

Save this as `workflowtemplate-request-environment.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: WorkflowTemplate
metadata:
  name: request-environment
  namespace: starfleet
spec:
  entrypoint: request
  serviceAccountName: provisioner
  arguments:
    parameters:
      - name: name
        value: outpost-env
      - name: team
        value: outpost
  templates:
    - name: request
      resource:
        action: create
        successCondition: status.phase == Ready
        failureCondition: status.phase == Failed
        manifest: |
          apiVersion: platform.starfleet.io/v1alpha1
          kind: TeamEnvironment
          metadata:
            name: {{workflow.parameters.name}}
            namespace: outpost
          spec:
            team: {{workflow.parameters.team}}
            replicas: 1
```

Apply it:

```bash
kubectl apply -f workflowtemplate-request-environment.yaml
```

Then check the result:

```bash
kubectl -n starfleet get workflowtemplate request-environment
```

The template is stored. The template check of the grader passes now.

## Step 3: Run it and play the controller

Save this as `workflow-request-environment.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: request-environment-
  namespace: starfleet
spec:
  serviceAccountName: provisioner
  workflowTemplateRef:
    name: request-environment
```

Create it and look at the object and the Workflow:

```bash
kubectl create -f workflow-request-environment.yaml
kubectl -n outpost get teamenvironments
kubectl -n starfleet get workflows
```

The `TeamEnvironment` `outpost-env` exists, and the newest Workflow stays in the phase `Running`. The step pod is watching the object. This is the wait you built.

Now write the status, as a controller would:

```bash
kubectl -n outpost patch teamenvironment outpost-env --subresource=status --type=merge -p '{"status":{"phase":"Ready"}}'
kubectl -n starfleet get workflows
```

After a few seconds the Workflow changes to `Succeeded`. The wait check of the grader does the same with `Ready` and with `Failed`, and it also checks that the Workflow was still `Running` before the status was written.

## If the Workflow does not behave

* The Workflow ends as `Failed` before you write the status: read the message of the node with `kubectl -n starfleet get workflows -o jsonpath='{range .items[-1].status.nodes.*}{.displayName}{"\t"}{.phase}{"\t"}{.message}{"\n"}{end}'`. A `forbidden` message means a verb is missing. Watching needs `list` and `watch`, not only `get`.
* The Workflow ends as `Succeeded` at once: the step has no `successCondition`, so it stops when the object is created.
* The Workflow stays `Running` after `Failed`: the step has no `failureCondition`.
* The object is created a second time with the same name: a `create` of a fixed name fails with `AlreadyExists`. Pass a new `name` parameter.
