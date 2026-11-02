# Solution Walkthrough

You work on the `terminal` of the lab cluster. You finish a self-service path with seven changes: two sets of RBAC for tenants and the Workflow, a WorkflowTemplate, a repaired EventSource, RBAC for the Sensor and a repaired Sensor. Crossplane, the `TeamEnvironment` API and its Composition stay as they are.

| Goal | Object | Where |
| --- | --- | --- |
| Let the tenant file and read requests | Role and RoleBinding for the group `outpost-team` | `outpost` |
| Let the Workflow create the request | Role and RoleBinding for the ServiceAccount `provisioner` | `outpost` |
| Create the request and wait for it | WorkflowTemplate `request-environment` | `starfleet` |
| Receive the order on the right path | EventSource `provision` | `starfleet` |
| Let the Sensor start Workflows | Role and RoleBinding for the ServiceAccount `operate-workflow-sa` | `starfleet` |
| Filter the order and pass the team | Sensor `provision` | `starfleet` |

## The feedback loop

Grading runs from the host terminal, the shell where you typed `astrona run`, not inside the cluster:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/capstone/labs/lab-01
```

The grader has seven checks: `tenant-rbac`, `provisioner-rbac`, `template-shape`, `webhook`, `sensor-rbac`, `filter-and-mapping` and `order-ready`. At the start `provisioner-rbac` to `order-ready` fail, because nothing exists yet. Run the command after each step and read which checks turned green. The last two checks send real orders and take a few minutes.

---

## Step 1: Give the tenant group the rights to file requests

The tenant rights must be a Role in `outpost`, not a ClusterRole, and the RoleBinding must name the group, so every member gets the rights. Save this as `rbac-tenant.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: teamenvironment-requester
  namespace: outpost
rules:
  - apiGroups: ["platform.starfleet.io"]
    resources: ["teamenvironments"]
    verbs: ["create", "get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: outpost-team-teamenvironment-requester
  namespace: outpost
subjects:
  - kind: Group
    name: outpost-team
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: teamenvironment-requester
  apiGroup: rbac.authorization.k8s.io
```

Apply it:

```sh
kubectl apply -f rbac-tenant.yaml
```

Then check what a member of the group can do:

```sh
kubectl auth can-i create teamenvironments -n outpost --as outpost-dev --as-group outpost-team
kubectl auth can-i delete teamenvironments -n outpost --as outpost-dev --as-group outpost-team
```

The first command answers `yes`. The second answers `no`. Submit now: the check `tenant-rbac` passes.

## Step 2: Give the Workflow identity the same rights

The steps of a Workflow run as the ServiceAccount `provisioner` in `starfleet`. The Workflow creates the `TeamEnvironment` in `outpost` and then waits for it, so the ServiceAccount needs `create`, `get`, `list` and `watch` in `outpost`. It does not need `update`, `patch` or `delete`. Save this as `rbac-provisioner.yaml`:

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

```sh
kubectl apply -f rbac-provisioner.yaml
```

Then check it:

```sh
kubectl auth can-i create teamenvironments -n outpost --as system:serviceaccount:starfleet:provisioner
kubectl auth can-i create deployments -n outpost --as system:serviceaccount:starfleet:provisioner
```

The first command answers `yes` and the second answers `no`. Submit: the check `provisioner-rbac` passes.

## Step 3: Create the WorkflowTemplate

The template has one resource step. The step creates the `TeamEnvironment` with the `team` parameter as its name and `spec.team`. The `successCondition` keeps the step running until the Composition reports available replicas in `status.availableReplicas`. Without it, the step ends right after the create and the Workflow shows `Succeeded` while the environment is still starting. Save this as `workflowtemplate-request-environment.yaml`:

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
      - name: team
  templates:
    - name: request
      resource:
        action: create
        successCondition: status.availableReplicas > 0
        manifest: |
          apiVersion: platform.starfleet.io/v1alpha1
          kind: TeamEnvironment
          metadata:
            name: {{workflow.parameters.team}}
            namespace: outpost
          spec:
            team: {{workflow.parameters.team}}
```

Apply it:

```sh
kubectl apply -f workflowtemplate-request-environment.yaml
```

Then check the fields:

```sh
kubectl -n starfleet get workflowtemplate request-environment -o jsonpath='{.spec.templates[0].resource.successCondition}'
```

Submit: the check `template-shape` passes.

## Step 4: Repair the EventSource endpoint

The EventSource listens on `/order`, but orders arrive on `/provision`. Save the corrected object as `eventsource-provision.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: EventSource
metadata:
  name: provision
  namespace: starfleet
spec:
  service:
    ports:
      - port: 12000
        targetPort: 12000
  webhook:
    request:
      port: "12000"
      endpoint: /provision
      method: POST
```

Apply it:

```sh
kubectl apply -f eventsource-provision.yaml
```

The Argo Events controller restarts the EventSource pod. Wait for the new pod, then send a test order from `shuttle`:

```sh
kubectl -n starfleet get pods -l eventsource-name=provision
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w "%{http_code}\n" -X POST -H "Content-Type: application/json" -d '{"team":"test","tier":"trial"}' http://provision-eventsource-svc.starfleet.svc:12000/provision
```

The request returns `200` once the new pod runs. The tier `trial` is not a valid order, so the Sensor must drop it later, and no Workflow starts. Submit: the check `webhook` passes.

## Step 5: Give the Sensor the right to create Workflows

The Sensor pod runs as `operate-workflow-sa`. It creates a Workflow in `starfleet` for each accepted event. It needs nothing in `outpost`. Save this as `rbac-sensor.yaml`:

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
kubectl apply -f rbac-sensor.yaml
```

Then check it:

```sh
kubectl auth can-i create workflows -n starfleet --as system:serviceaccount:starfleet:operate-workflow-sa
kubectl auth can-i create teamenvironments -n outpost --as system:serviceaccount:starfleet:operate-workflow-sa
```

The first command answers `yes` and the second answers `no`. Submit: the check `sensor-rbac` passes.

## Step 6: Repair the Sensor

The Sensor has two faults. It accepts every tier, and it does not copy `body.team` into the Workflow. The data filter on the dependency drops events whose `body.tier` is not `standard` or `premium`. The trigger parameter copies `body.team` from the event into the first parameter of the Workflow. Save the corrected object as `sensor-provision.yaml`:

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
      filters:
        data:
          - path: body.tier
            type: string
            value:
              - standard
              - premium
  triggers:
    - template:
        name: submit-request-environment
        argoWorkflow:
          operation: submit
          source:
            resource:
              apiVersion: argoproj.io/v1alpha1
              kind: Workflow
              metadata:
                generateName: request-environment-
              spec:
                serviceAccountName: provisioner
                arguments:
                  parameters:
                    - name: team
                      value: unset
                workflowTemplateRef:
                  name: request-environment
          parameters:
            - src:
                dependencyName: request-dep
                dataKey: body.team
              dest: spec.arguments.parameters.0.value
```

Apply it:

```sh
kubectl apply -f sensor-provision.yaml
```

The Sensor pod restarts. Wait for it, then submit: the check `filter-and-mapping` passes.

## Step 7: Prove the whole path

Send a standard order from `shuttle` in `starfleet`:

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s -X POST -H "Content-Type: application/json" -d '{"team":"drifter","tier":"standard"}' http://provision-eventsource-svc.starfleet.svc:12000/provision
```

Then follow the path. The Workflow named `request-environment-` plus a random suffix appears, the `TeamEnvironment` `drifter` appears in `outpost`, and the Workflow ends as `Succeeded` after the Deployment has had an available replica:

```sh
kubectl -n starfleet get workflows
kubectl -n outpost get teamenvironments
kubectl -n outpost exec deploy/shuttle -- curl -s -o /dev/null -w "%{http_code}\n" http://scout:9898
```

The last request returns `200`. Remove your test environment before you submit, because only one environment can run in `outpost`:

```sh
kubectl -n outpost delete teamenvironment drifter
```

Submit: the check `order-ready` passes. The grader removes every `TeamEnvironment` in `outpost`, sends its own order and checks the result.

---

## If a check fails

- `tenant-rbac` fails on "another member": the RoleBinding names the user `outpost-dev`. Bind the group `outpost-team`.
- `template-shape` fails on the `successCondition`: the step ends right after the create. Add the condition `status.availableReplicas > 0`.
- `webhook` fails with a `404` or no answer: the EventSource pod has not restarted yet, or the endpoint is not `/provision`. Read the pod with `kubectl -n starfleet get pods -l eventsource-name=provision`.
- `filter-and-mapping` fails with "no Workflow has the team parameter": read the Sensor log with `kubectl -n starfleet logs -l sensor-name=provision`. A `forbidden` error means the Role from step 5 is missing.
- `order-ready` fails with "Succeeded while status.availableReplicas is empty": the WorkflowTemplate has no working `successCondition`.
- `order-ready` fails with a Workflow in `Error` or `Failed`: read the node status with `kubectl -n starfleet get workflow <name> -o yaml`. A `forbidden` error on `teamenvironments` means the Role from step 2 is missing.
