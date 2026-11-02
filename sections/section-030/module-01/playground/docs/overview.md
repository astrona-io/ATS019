# Overview: Install A Crossplane Provider And ProviderConfig (Playground)

This playground gives you a clean Crossplane control plane to install a provider on, break and repair. A provider is a Crossplane package that adds custom resource definitions (CRDs) and a controller for one external system. There is nothing to submit and no grading.

## What's in the box

The single-node `kind` cluster runs Kubernetes 1.35.8 and Crossplane 2.4.2. Crossplane is the open source framework that turns a Kubernetes cluster into a control plane for other systems.

| Namespace | Objects |
| --- | --- |
| `crossplane-system` | The Deployments `crossplane` and `crossplane-rbac-manager` |
| `starfleet` | Empty. The platform team's namespace |
| `outpost` | Empty. The tenant team's namespace, where ProviderConfigs and managed resources go |

No provider is installed. When you install one, Crossplane pulls the package from `xpkg.crossplane.io`, so the cluster needs outbound internet access and the first install takes from a few seconds to a few minutes.

## Helper

Paste this function into each new terminal. `show_sync` prints the `Synced` and `Ready` conditions of a managed resource with their reasons, so you can compare them after every change. It only reads objects.

```sh
show_sync() {
  kubectl -n "$1" get "$2" "$3" \
    -o jsonpath='{range .status.conditions[*]}{.type}{" "}{.status}{" reason="}{.reason}{"\n"}{end}'
}
```

Use it as `show_sync outpost objects.kubernetes.m.crossplane.io scout`.

## Practice tasks

- Install `provider-kubernetes` 1.4.1 with a `DeploymentRuntimeConfig` that fixes the ServiceAccount name. Compare `kubectl get providers` right after the apply and again when the provider pod runs.
- Find the CRDs the package added. Compare the group `kubernetes.m.crossplane.io` with the group `kubernetes.crossplane.io`.
- Create a `ProviderConfig` in `outpost` with the `InjectedIdentity` source. Run `kubectl auth can-i` as the provider's ServiceAccount for several verbs and resources, and write down what it may do.
- Create an `Object` that wraps a Service. Read the `Synced` condition, find the `forbidden` message, then grant the smallest Role that fixes it.
- Delete the `Object` and check that the provider removes the Service it created.
- Break the Role again (remove the `create` verb) and watch how long the provider takes to report `Synced False`.
