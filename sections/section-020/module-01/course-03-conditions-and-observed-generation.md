# Read Conditions And observedGeneration

The owned objects show what a controller built. The custom resource's `status` shows what the controller thinks about its own work. A platform engineer reads `status` first, because it answers two questions at once: did the controller finish, and did it see the latest change?

## Conditions: the controller's report

A condition is an entry in `status.conditions`. It has a `type` (what is being reported), a `status` (`True`, `False` or `Unknown`), a `reason` (one CamelCase word a program can match) and a `message` (text for a person). Most Kubernetes controllers write conditions in this shape, so once you can read one you can read them all.

<!-- astrona:playground:renew -->

The `Prometheus` resource `starfleet` may still be starting again after the StatefulSet changes you made by hand. Wait until it reports `Available`:

```sh
kubectl -n starfleet wait --for=condition=Available --timeout=120s prometheus/starfleet
```

You should see:

```text
prometheus.monitoring.coreos.com/starfleet condition met
```

`kubectl wait --for=condition=<type>` works on any object with conditions, including custom resources. Now print each condition on one line, together with the object's generation:

```sh
kubectl -n starfleet get prometheus starfleet \
  -o jsonpath='{range .status.conditions[*]}{.type}{" "}{.status}{" observedGeneration="}{.observedGeneration}{"\n"}{end}'
kubectl -n starfleet get prometheus starfleet -o jsonpath='{.metadata.generation}{"\n"}'
```

You should see:

```text
Available True observedGeneration=1
Reconciled True observedGeneration=1
1
```

The Prometheus Operator writes two conditions. `Reconciled` says whether the last reconcile worked: the operator built every object without an error. `Available` says whether the pods of the StatefulSet are ready. They answer different questions, and one can be `True` while the other is `False`.

## generation and observedGeneration

The API server keeps a counter in `metadata.generation`. For a custom resource with the `status` subresource, such as `Prometheus`, it adds one each time the `spec` changes; changes to `status`, labels or annotations do not count. A controller copies the generation it acted on into `observedGeneration`. The Prometheus Operator writes it into every condition.

When `observedGeneration` is lower than `generation`, the status describes an older `spec`. The controller has not acted on your latest change yet: it may be busy, slow or not running at all. To see this happen, stop the controller by scaling its Deployment to zero:

```sh
kubectl -n default scale deployment prometheus-operator --replicas=0
kubectl -n default wait --for=delete pod -l app.kubernetes.io/name=prometheus-operator --timeout=60s
```

You should see (the pod name differs):

```text
deployment.apps/prometheus-operator scaled
pod/prometheus-operator-85855c675-dl8xg condition met
```

Now change the `spec`: ask Prometheus to log at the `debug` level. Then compare the two numbers:

```sh
kubectl -n starfleet patch prometheus starfleet --type merge -p '{"spec":{"logLevel":"debug"}}'
kubectl -n starfleet get prometheus starfleet \
  -o jsonpath='generation={.metadata.generation} observed={.status.conditions[?(@.type=="Reconciled")].observedGeneration}{"\n"}'
```

You should see:

```text
prometheus.monitoring.coreos.com/starfleet patched
generation=2 observed=1
```

The API server stored the change and raised the generation to 2. The conditions still say `observedGeneration` 1, and they still say `True`. Without the generation check, a status of `Reconciled True` would look like proof that your change worked. Check the StatefulSet, where the operator would pass the log level to Prometheus as the start flag `--log.level`:

```sh
kubectl -n starfleet get statefulset prometheus-starfleet \
  -o jsonpath='{.spec.template.spec.containers[?(@.name=="prometheus")].args}{"\n"}'
```

You should see:

```text
["--config.file=/etc/prometheus/config_out/prometheus.env.yaml","--web.enable-lifecycle","--web.route-prefix=/","--storage.tsdb.path=/prometheus","--web.config.file=/etc/prometheus/web_config/web-config.yaml"]
```

There is no `--log.level` flag. Nothing acted on the change, because no controller is running. Start the controller again:

```sh
kubectl -n default scale deployment prometheus-operator --replicas=1
kubectl -n default rollout status deployment prometheus-operator --timeout=120s
```

You should see:

```text
deployment.apps/prometheus-operator scaled
Waiting for deployment "prometheus-operator" rollout to finish: 0 of 1 updated replicas are available...
deployment "prometheus-operator" successfully rolled out
```

When the controller starts, it lists every `Prometheus` resource and reconciles each one. Give it a few seconds, then read both places again:

```sh
kubectl -n starfleet get prometheus starfleet \
  -o jsonpath='generation={.metadata.generation} observed={.status.conditions[?(@.type=="Reconciled")].observedGeneration}{"\n"}'
kubectl -n starfleet get statefulset prometheus-starfleet \
  -o jsonpath='{.spec.template.spec.containers[?(@.name=="prometheus")].args}{"\n"}'
```

You should see:

```text
generation=2 observed=2
["--config.file=/etc/prometheus/config_out/prometheus.env.yaml","--web.enable-lifecycle","--web.route-prefix=/","--log.level=debug","--storage.tsdb.path=/prometheus","--web.config.file=/etc/prometheus/web_config/web-config.yaml"]
```

The two numbers match, and the StatefulSet now carries `--log.level=debug`. The controller caught up with the change it missed. It did not need a new event for this: a reconcile reads the whole desired state every time, not only the last change.

> [!TIP]
> Check `observedGeneration` against `metadata.generation` before you trust any condition. If they differ, look at the controller (is it running, what do its logs say) before you look at the custom resource.

You can now read a controller's conditions, tell `Reconciled` from `Available`, and prove whether a status is current with `observedGeneration`. A controller that is down leaves old but healthy-looking status behind. The open question is what the status looks like when the controller runs but cannot finish.

## Common pitfalls

> [!WARNING]
> - **Trusting `True` without the generation.** A condition with an old `observedGeneration` describes an older `spec`.
> - **Expecting `generation` to change for every edit.** Only `spec` changes raise it. A new label or annotation does not.
> - **Reading only one condition.** `Reconciled True` means the operator built its objects; it does not mean the pods run. Read `Available` too.
> - **Leaving the controller scaled down.** Every custom resource of that kind stops being reconciled until the controller runs again.
