# Overview: Read An Operator's Reconcile Loop (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the Prometheus Operator, one `Prometheus` resource that works and one that cannot start. There is no task, no `astrona submit` and no pass or fail. Read the operator, break its objects, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- The Prometheus Operator 0.94.1 in the namespace `default`: the Deployment `prometheus-operator`, its ServiceAccount, its ClusterRole and ClusterRoleBinding, and ten CRDs in the API group `monitoring.coreos.com`.
- In the namespace `starfleet`:

  | Object | What it is |
  | --- | --- |
  | `Prometheus` `starfleet` | One Prometheus server that runs and reports `Available True` |
  | `Prometheus` `broken` | Names the ServiceAccount `prometheus-reader`, which does not exist, so its pod is never created |
  | ServiceAccount `prometheus` | The identity the Prometheus servers run as, with read access to Services, Endpoints, EndpointSlices and Pods |
  | `scout` Deployment and Service | podinfo, a small web API on port `9898` that serves metrics on `/metrics` |
  | ServiceMonitor `scout` | Tells a Prometheus server with `serviceMonitorSelector` `team: starfleet` to collect metrics from `scout` |
  | `shuttle` | A client pod with `curl` |

- The operator, Prometheus, config reloader, podinfo and curl images are already on the node.

## Helpers

Paste these once in each new terminal. `show_conditions` prints each condition of a `Prometheus` resource with its `observedGeneration`, and then its `metadata.generation`. `show_owned` lists the StatefulSets, Services and Secrets in `starfleet` with the names of their owners. `operator_errors` prints the latest error lines from the operator's log.

```sh
show_conditions() {
  kubectl -n starfleet get prometheus "$1" \
    -o jsonpath='{range .status.conditions[*]}{.type}{" "}{.status}{" reason="}{.reason}{" observedGeneration="}{.observedGeneration}{" "}{.message}{"\n"}{end}generation={.metadata.generation}{"\n"}'
}
show_owned() {
  kubectl -n starfleet get statefulset,service,secret \
    -o custom-columns='KIND:.kind,NAME:.metadata.name,OWNER:.metadata.ownerReferences[*].name'
}
operator_errors() {
  kubectl -n default logs deploy/prometheus-operator --since=5m | grep 'level=error' | tail -5
}
```

Use them like this: `show_conditions broken`, `show_owned`, `operator_errors`.

## Practice tasks

- List every kind the operator adds, then use `kubectl auth can-i --as` to find three things the operator's ServiceAccount may not do.
- Trace the pod `prometheus-starfleet-0` up to the `Prometheus` resource that caused it, one `ownerReference` at a time.
- Change the `Prometheus` resource `starfleet` while the operator is scaled to zero, and predict `generation` and `observedGeneration` before you start the operator again.
- Delete a Secret the operator created and find out how long it takes to come back. Then start a reconcile at once with an annotation on the `Prometheus` resource.
- Find from the events why `broken` has no pod, and fix it by changing only the `Prometheus` resource.
