# A Sensor That Submits A Workflow

The EventBus now holds events that nobody reads. A Sensor reads them. This part writes a Sensor that starts a Workflow from the WorkflowTemplate `provision-environment` when the webhook event arrives, and then finds out why the first trigger fails.

## What a Sensor is made of

A Sensor is a custom resource with two lists. `dependencies` names the events the Sensor waits for. `triggers` names the actions the Sensor runs when the dependencies are met. Each dependency has a `name` of your choice, an `eventSourceName` and an `eventName`. The last two must match the EventSource name and the name under `webhook` exactly.

A trigger of type `argoWorkflow` creates or changes a Workflow. With `operation: submit` it creates a new Workflow from the resource in `source`. That resource can use `workflowTemplateRef`, so it points to a stored WorkflowTemplate instead of repeating its steps. The `generateName` field gives each Workflow a unique name.

A Sensor runs as a pod, and that pod uses a ServiceAccount to send requests to the Kubernetes API server. The field `spec.template.serviceAccountName` selects it. The Sensor pod, not the Argo Workflows controller, creates the Workflow object. So the ServiceAccount needs permission to create Workflows.

## Write the Sensor

The playground has a ServiceAccount named `operate-workflow-sa` in `starfleet`. It exists, but it has no Role yet.

Save this as `sensor-provision.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Sensor
metadata:
  name: provision
  namespace: starfleet
spec:
  template:
    serviceAccountName: operate-workflow-sa
  dependencies:
    - name: request-dep
      eventSourceName: provision
      eventName: request
  triggers:
    - template:
        name: submit-provision
        argoWorkflow:
          operation: submit
          source:
            resource:
              apiVersion: argoproj.io/v1alpha1
              kind: Workflow
              metadata:
                generateName: provision-environment-
              spec:
                arguments:
                  parameters:
                    - name: team
                      value: unset
                workflowTemplateRef:
                  name: provision-environment
```

<!-- astrona:playground:renew -->

Apply it:

```sh
kubectl apply -f sensor-provision.yaml
```

Then check the result:

```sh
kubectl -n starfleet get sensor provision
kubectl -n starfleet get pods -l sensor-name=provision
```

The controller creates one pod for the Sensor. Wait until it runs. The `team` value is the fixed text `unset` for now. The next part replaces it with a value from the event.

## Send an event and find the failure

Send the same request as before:

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' \
  -X POST -H 'Content-Type: application/json' \
  -d '{"team":"outpost","tier":"standard"}' \
  http://provision-eventsource-svc.starfleet.svc:12000/provision
```

The EventSource still answers `200`. Now list the Workflows:

```sh
kubectl -n starfleet get workflows
```

You should see no Workflow. The event reached the Sensor, but the trigger failed. The EventSource cannot show this, because it only publishes events. The Sensor log shows it:

```sh
kubectl -n starfleet logs -l sensor-name=provision
```

Look for an error that says `forbidden`. It names the ServiceAccount `system:serviceaccount:starfleet:operate-workflow-sa` and says it cannot create the resource `workflows` in the API group `argoproj.io`. Kubernetes role-based access control (RBAC) refused the request.

## Grant only the permission the trigger needs

A Role lists permissions in one namespace. A RoleBinding gives those permissions to an identity. The trigger creates Workflows, so grant `create` on `workflows`. Add `get`, `list` and `watch` so the Sensor can read back what it made. The Workflow points at a WorkflowTemplate, and the submit step reads that template first, so also grant `get` on `workflowtemplates`. Without it, the Sensor log shows `PermissionDenied ... cannot get resource "workflowtemplates"`. Do not give the ServiceAccount `cluster-admin` or a wildcard on every resource.

Save this as `role-sensor-workflows.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: sensor-workflows
  namespace: starfleet
rules:
  - apiGroups: ["argoproj.io"]
    resources: ["workflows"]
    verbs: ["create", "get", "list", "watch"]
  - apiGroups: ["argoproj.io"]
    resources: ["workflowtemplates"]
    verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sensor-workflows
  namespace: starfleet
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: sensor-workflows
subjects:
  - kind: ServiceAccount
    name: operate-workflow-sa
    namespace: starfleet
```

Apply it:

```sh
kubectl apply -f role-sensor-workflows.yaml
```

Then check the permission, and send the event again:

```sh
kubectl -n starfleet auth can-i create workflows.argoproj.io --as=system:serviceaccount:starfleet:operate-workflow-sa
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' \
  -X POST -H 'Content-Type: application/json' \
  -d '{"team":"outpost","tier":"standard"}' \
  http://provision-eventsource-svc.starfleet.svc:12000/provision
kubectl -n starfleet get workflows
```

The first command should print `yes`. After the second request, a Workflow with a name that starts with `provision-environment-` should appear. The Argo Workflows controller then runs its pods.

You can now connect an event to a Workflow and tell apart who did what. The EventSource received the request, the Sensor ran the trigger, and RBAC decided whether the Sensor could create the Workflow. The Workflow still ignores the event body. The next part fixes that and keeps unwanted events out.

## Common pitfalls

> [!WARNING]
> - **Reading only the EventSource log.** It shows `200` and a published event even when the Sensor fails. Read the Sensor log next.
> - **`eventName` that does not match the key under `webhook`.** Here it must be `request`, not `provision`.
> - **Granting `cluster-admin` to fix `forbidden`.** One Role with `create` on `workflows` is enough.
> - **Expecting the failed event to run again after the fix.** Send a new event and check for a new Workflow.
