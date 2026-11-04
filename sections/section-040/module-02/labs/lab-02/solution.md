# Solution

This walkthrough follows the event from the request to the Workflow and stops at the first component that does not do its job.

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-02/labs/lab-02
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

## Step 1: Follow the event along its path

Start with the request. Send an event from `shuttle`:

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' \
  -X POST -H 'Content-Type: application/json' \
  -d '{"team":"drifter","tier":"standard"}' \
  http://provision-eventsource-svc.starfleet.svc:12000/provision
```

The request returns `200`, so the EventSource accepted it. That proves nothing about the Sensor. Check that no Workflow exists:

```sh
kubectl -n starfleet get workflows
```

Read the status and log of the EventSource, then the status and log of the Sensor:

```sh
kubectl -n starfleet get eventsource provision -o jsonpath='{.status.conditions}{"\n"}'
kubectl -n starfleet logs -l eventsource-name=provision --tail=20
kubectl -n starfleet get sensor provision -o jsonpath='{.status.conditions}{"\n"}'
kubectl -n starfleet logs -l sensor-name=provision --tail=20
```

The EventSource does its job: it receives the request and publishes the event. The Sensor log has no `forbidden` error, so RBAC is not the cause. The Sensor never starts a trigger. The names in the dependency match the EventSource, so the next place to look is the data filter.

## Step 2: Compare the filter path with the event

Read the dependency of the Sensor:

```sh
kubectl -n starfleet get sensor provision -o jsonpath='{.spec.dependencies}{"\n"}'
```

The filter path is `tier`. A webhook event keeps the posted JSON under `body`, next to `header`, so the field is at `body.tier`. The path `tier` never matches, and the Sensor drops every event. The EventSource and the Role are correct.

## Step 3: Fix the path in the Sensor

Do not remove the filter. The platform still accepts only `standard` and `premium`. Do not change the EventSource and do not widen the permissions.

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

Then wait for the Sensor pod to be replaced and ready:

```sh
kubectl -n starfleet get pods -l sensor-name=provision
```

## Step 4: Prove the fix

Send a new event. The event from step 1 does not run again.

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' \
  -X POST -H 'Content-Type: application/json' \
  -d '{"team":"drifter","tier":"standard"}' \
  http://provision-eventsource-svc.starfleet.svc:12000/provision
kubectl -n starfleet get workflows
```

A Workflow with a name that starts with `provision-environment-` should appear, and it should end as `Succeeded`. Check its team value:

```sh
kubectl -n starfleet get workflows -o jsonpath='{.items[*].spec.arguments.parameters[0].value}{"\n"}'
```

The watch terminal now shows all five checks passing. Press Ctrl-C to stop the watch, then run the submit command once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-02/labs/lab-02
```

## If a check fails

- Check 1 fails: you changed the EventSource, the EventBus or the dependency of the Sensor. Restore the original names, the endpoint `/provision`, the method `POST` and the port `12000`.
- Check 2 fails: wait until the new Sensor pod runs, then send a new event. The Sensor log shows whether the event arrived.
- Check 3 fails: the filter is gone or too wide. A request with the tier `trial` must start no Workflow.
- Check 4 fails: the Sensor ServiceAccount has a wildcard or access to Secrets. Remove it.
- Check 5 fails: read the Workflow status and the logs of its pod.
