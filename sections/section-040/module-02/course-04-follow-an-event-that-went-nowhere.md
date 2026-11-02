# Follow An Event That Went Nowhere

An event reaches the platform, the client sees `200`, and no Workflow starts. The cause can sit in four places: the request, the EventSource, the Sensor, or the permissions of the Sensor. Guessing wastes time. This part shows a fixed order of checks that moves along the path of the event and stops at the first break.

## Walk the path in order

Follow the same path the event takes. At each step, one component either did its job or did not. The order below goes from the outside in.

<!-- astrona:playground:renew -->

Step one is the request. Check the HTTP status code that `curl` prints, with the same command you used before:

```sh
kubectl -n starfleet exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' \
  -X POST -H 'Content-Type: application/json' \
  -d '{"team":"outpost","tier":"standard"}' \
  http://provision-eventsource-svc.starfleet.svc:12000/provision
```

A `404` means the endpoint is wrong. A refused method gives an error status. A failure to resolve the name means the Service does not exist. Only `200` moves the problem to the next step.

Step two is the EventSource. Read its status and its log:

```sh
kubectl -n starfleet get eventsource provision -o jsonpath='{.status.conditions}{"\n"}'
kubectl -n starfleet logs -l eventsource-name=provision --tail=20
```

A condition is an entry with a `type`, a `status`, a `reason` and a `message`. A `False` condition with a message tells you why the EventSource is not ready, for example that the EventBus is missing. If the status is healthy and the log shows the published event, the EventSource did its job.

Step three is the Sensor. Read its status and its log:

```sh
kubectl -n starfleet get sensor provision -o jsonpath='{.status.conditions}{"\n"}'
kubectl -n starfleet logs -l sensor-name=provision --tail=20
```

The Sensor log shows whether the event arrived, whether the trigger ran and what error the trigger returned. Step four is the Workflow itself. If the trigger succeeded, list the Workflows. If a Workflow exists but fails, the problem is now in Argo Workflows, not in Argo Events.

## Match the symptom to the cause

Each symptom points to one component. The table is a reference for what you read in the steps above.

| What you see | Component | Likely cause |
| --- | --- | --- |
| `404` or a refused method from `curl` | EventSource | Wrong `endpoint` or `method` |
| Name does not resolve | EventSource | No `service` block, so no Service |
| EventSource or Sensor condition `False` | EventBus | Missing bus, or a bus not named `default` |
| `200`, event in EventSource log, nothing in Sensor log | Sensor | `eventSourceName` or `eventName` does not match |
| Sensor log shows an event but no trigger | Sensor | A data filter dropped it, for example a wrong `path` or `value` |
| Sensor log says `forbidden` | RBAC | The Sensor ServiceAccount cannot create Workflows |
| Workflow exists but fails | Argo Workflows | Template or parameter problem |

## Break the Sensor on purpose

Change the dependency to a wrong event name and watch the symptom. Edit `sensor-provision.yaml` and set `eventName: requests`. Apply the file, wait for the Sensor pod to run again, and send the event.

```sh
kubectl apply -f sensor-provision.yaml
kubectl -n starfleet get pods -l sensor-name=provision
```

The request still returns `200`, and the EventSource log still shows a published event. The Sensor never sees it, because it waits for an event named `requests`. No Workflow starts, and the Sensor log has no trigger error. Set `eventName: request` again and apply the file to repair it.

You now have a repeatable method. Start at the request, then read the EventSource, then the Sensor, and look at the first component whose evidence does not match what it should have done. Most failures show up as a status code, a condition message, or an error in a log, never as silence.

## Common pitfalls

> [!WARNING]
> - **Stopping at `200`.** It proves only that the EventSource accepted the request.
> - **Skipping the Sensor log.** Filter drops, name mismatches and `forbidden` errors all show there.
> - **Fixing RBAC with a broad role.** Grant `create` on `workflows` in the namespace, and nothing more.
> - **Changing the Workflow when the event never arrived.** Find the first component that did not do its job.

## Your mission: Find Why An Event Starts No Workflow

You can now trace one event along the path and name the component that broke it. The mission gives you a Sensor that receives events but starts no Workflow. Find the fault, fix it in the right object, and prove it with a request from `shuttle`.

Pause the playground first:

```sh
astrona stop ats-019-playground-040-02
```

Run the lab and submit your work:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-02/labs/lab-02
astrona submit -c sections/section-040/module-02/labs/lab-02
```

When you finish, remove the lab and start the playground again:

```sh
astrona destroy ats-019-lab-040-02-02
astrona start ats-019-playground-040-02
```
