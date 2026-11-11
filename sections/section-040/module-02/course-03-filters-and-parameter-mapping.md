# Filters And Parameter Mapping

The Sensor from the last part submits a Workflow for every event, and it always passes the text `unset` as the team. A real platform API needs two more things. It must ignore events that are not valid requests, and it must pass the request data to the Workflow. A data filter does the first job. A trigger parameter does the second.

## Filter on the event data

A filter on a dependency decides if the Sensor accepts an event. The Sensor drops an event that does not match, and it runs no trigger. A data filter looks at the `data` part of the event. For a webhook event, `data` has `header` and `body`. A path that points into the JSON you posted starts with `body.`, for example `body.tier`.

A data filter has a `path`, a `type` (such as `string`), and a list of `value` entries. For a string, the Sensor treats each value as a regular expression, and the event matches when one value matches. The dependency below accepts only events whose `tier` is `standard` or `premium`.

## Map a value into a Workflow parameter

A trigger parameter copies a value from an event into the trigger's resource before the Sensor creates it. The `src` part names the dependency (`dependencyName`) and the key in the event (`dataKey`). The `dest` part gives the field to overwrite in the resource, written as a dotted path.

In the Sensor, the first entry of `spec.arguments.parameters` is the `team` parameter. Its path is `spec.arguments.parameters.0.value`, where `0` is the position in the list. So `dataKey: body.team` with that `dest` puts the posted team name into the Workflow.

Save the changed Sensor as `sensor-provision.yaml`, replacing the earlier file:

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

<!-- astrona:playground:renew -->

Apply it:

```sh
kubectl apply -f sensor-provision.yaml
```

Then check that the Sensor pod runs again. The controller replaces the pod when the Sensor changes.

```sh
kubectl -n starfleet get pods -l sensor-name=provision
```

## Send one valid and one invalid event

Send a valid request for the team `outpost`, and then read the `team` value of the newest Workflow:

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' \
  -X POST -H 'Content-Type: application/json' \
  -d '{"team":"outpost","tier":"standard"}' \
  http://provision-eventsource-svc.starfleet.svc:12000/provision
kubectl -n starfleet get workflows -o jsonpath='{.items[*].spec.arguments.parameters[0].value}{"\n"}'
```

The request returns `200`. The Workflow list should show `outpost` for the new Workflow, not `unset`. The Workflow created in the last part still shows `unset`, because it came from the old Sensor.

Now send a request with a tier the filter does not accept:

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' \
  -X POST -H 'Content-Type: application/json' \
  -d '{"team":"drifter","tier":"trial"}' \
  http://provision-eventsource-svc.starfleet.svc:12000/provision
kubectl -n starfleet get workflows
```

The EventSource still returns `200`, because it accepts any valid request on that endpoint. No Workflow for `drifter` appears. The Sensor dropped the event at the filter. The caller gets no error, so the filter is a rule inside the platform, not a response to the tenant.

The Sensor can now accept the right events and pass their data on. The next question is the one you meet most often: an event was sent, `200` came back, and nothing started. The final part gives a fixed order of checks.

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

## Common pitfalls

> [!WARNING]
> - **A path without `body.`** The path `team` finds nothing. Webhook data has `header` and `body`, so use `body.team`.
> - **Posting without the JSON header.** The body is then not parsed as JSON, so a filter or `dataKey` on `body.team` fails.
> - **A wrong `dest` index.** `parameters.0` is the first entry in the list. Count from zero, and keep the parameter in the resource so the path exists.
> - **Expecting an error for a filtered event.** The EventSource returns `200`. Only the missing Workflow shows the drop.
