# Question

Solve this question on: `terminal`

A tenant team set `logLevel: debug` on its `Prometheus` resource named `starfleet` in the namespace `starfleet`. Hours later, the Prometheus server still logs at the default level. The `Prometheus` resource shows `Reconciled True` and `Available True`, so the tenant says the platform is wrong.

The Prometheus Operator is installed in the namespace `default`. Find out whether the status describes the current `spec`, find the reason, and repair it. Do not change the `Prometheus` resource, and do not edit the StatefulSet `prometheus-starfleet`: the controller must write it.

When you finish, these must be true:

- The controller of the Prometheus Operator runs: the Deployment `prometheus-operator` in `default` has a ready pod.
- The `Prometheus` resource `starfleet` still has `spec.logLevel: debug`, and it is the original resource, not a new one with the same name.
- The conditions `Reconciled` and `Available` of `starfleet` both have status `True`, and the `observedGeneration` of `Reconciled` equals `metadata.generation`.
- The StatefulSet `prometheus-starfleet` has a ready pod and starts Prometheus with the flag `--log.level=debug`. The controller wrote that flag, not you.
