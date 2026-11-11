# Solution

This walkthrough builds the path in the order of the event: the EventBus and the EventSource first, then the permission, then the Sensor.

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-02/labs/lab-01
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

Write each file in a new, empty folder and run every command from that folder.

## Step 1: Create the EventBus and the webhook EventSource

An EventBus carries events inside the namespace. An EventSource receives them. Both must exist before a Sensor can read anything. Save this as `eventbus-default.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: EventBus
metadata:
  name: default
  namespace: starfleet
spec:
  jetstream:
    version: latest
```

Apply it:

```sh
kubectl apply -f eventbus-default.yaml
```

Save this as `eventsource-provision.yaml`. The `service` block makes the controller create the Service `provision-eventsource-svc`. The name under `webhook` (`request`) is the event name the Sensor uses later.

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

Then check the result. Wait until the pods are ready, because the EventBus pods start first:

```sh
kubectl -n starfleet get eventbus,eventsource
kubectl -n starfleet get service provision-eventsource-svc
kubectl -n starfleet get pods
```

Send a first request from `shuttle`. It should print `200`:

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' \
  -X POST -H 'Content-Type: application/json' \
  -d '{"team":"outpost","tier":"standard"}' \
  http://provision-eventsource-svc.starfleet.svc:12000/provision
```

The watch terminal now shows Check 1 (the EventSource) passing.

## Step 2: Grant the Sensor ServiceAccount the permission to create Workflows

The Sensor pod, not the Argo Workflows controller, creates the Workflow. It uses the ServiceAccount `operate-workflow-sa`. A Role lists what it may do, and a RoleBinding gives the Role to the ServiceAccount. Grant `create` on `workflows`, plus `get`, `list` and `watch`. Do not grant `cluster-admin` or a wildcard.

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

Then check the permission. It should print `yes`:

```sh
kubectl -n starfleet auth can-i create workflows.argoproj.io --as=system:serviceaccount:starfleet:operate-workflow-sa
```

The watch terminal now shows Check 2 (the Sensor permissions) passing.

## Step 3: Create the Sensor with the filter and the parameter mapping

The dependency names the EventSource `provision` and the event `request`. The data filter reads `body.tier`, because a webhook event keeps the JSON you posted under `body`. The trigger parameter copies `body.team` into `spec.arguments.parameters.0.value`, the first entry of the parameter list of the Workflow.

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
      filters:
        data:
          - path: body.tier
            type: string
            value:
              - standard
              - premium
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

Then wait for the Sensor pod to run:

```sh
kubectl -n starfleet get pods -l sensor-name=provision
```

## Prove delivery before sending the task requests

A Ready Sensor Pod and an HTTP `200` from the EventSource do not prove that the Sensor has subscribed to JetStream. A request sent during startup can be accepted without creating a Workflow. After the bus and Pods are ready and the Sensor has its permissions and parameter mapping, send a disposable practice request:

```sh
PROBE="readiness-$(date +%s)"
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' \
  -X POST -H 'Content-Type: application/json' \
  -d "{\"team\":\"$PROBE\",\"tier\":\"standard\"}" \
  http://provision-eventsource-svc.starfleet.svc:12000/provision
kubectl -n starfleet get workflows -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.arguments.parameters[?(@.name=="team")].value}{"\n"}{end}'
```

Wait for a Workflow with that exact `team` value. If none appears, inspect the EventBus, EventSource and Sensor logs, then send the practice request again after startup completes. Stop after five minutes and diagnose the failure if no Workflow appears. The reference solution automates this bounded probe before running the graders, which then send their own unique requests.

This lab's Workflow only runs a practice task. Retrying a request can create more than one Workflow. A real provisioning endpoint needs a request identifier and duplicate handling before clients retry operations with side effects.

Send a valid request and a filtered request, and list the `team` values of the Workflows:

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' \
  -X POST -H 'Content-Type: application/json' \
  -d '{"team":"drifter","tier":"standard"}' \
  http://provision-eventsource-svc.starfleet.svc:12000/provision
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' \
  -X POST -H 'Content-Type: application/json' \
  -d '{"team":"trialteam","tier":"trial"}' \
  http://provision-eventsource-svc.starfleet.svc:12000/provision
kubectl -n starfleet get workflows -o jsonpath='{.items[*].spec.arguments.parameters[0].value}{"\n"}'
```

Both requests return `200`, because the EventSource accepts any valid request. Only the team `drifter` should appear in the Workflow list. The Sensor dropped the `trial` event at the filter.

The watch terminal now shows Checks 3, 4 and 5 passing. Press Ctrl-C to stop the watch, then run the submit command once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-02/labs/lab-01
```

## If a check fails

- Check 1 fails: the Service name is `<EventSource name>-eventsource-svc`, so the EventSource must be named `provision` and have a `service` block. Read the EventSource status and log.
- Check 2 fails: run the `can-i` command above. The grader also fails a wildcard, `cluster-admin` and access to Secrets.
- Check 3 fails and the Sensor log says `forbidden`: the Role or RoleBinding from step 2 is missing or names the wrong ServiceAccount.
- Check 3 fails and the Sensor log shows nothing: compare `eventSourceName` and `eventName` with the EventSource, and compare the filter path with the posted JSON.
- Check 4 fails: a filter that is missing, or that has a wrong path, accepts or drops the wrong events.
- Check 5 fails: read the Workflow status with `kubectl -n starfleet get workflows` and the logs of its pod.
