# Solution Walkthrough

You install `provider-kubernetes` 1.4.1 on the `terminal` of the lab cluster. You create two objects: a `DeploymentRuntimeConfig` that fixes the ServiceAccount name, and a `Provider` that names the package. Nothing else in the cluster changes.

| Goal | Where it lives | Object |
| --- | --- | --- |
| Ask Crossplane for a package | the `pkg.crossplane.io` API | `Provider` with `spec.package` |
| Fix the name of the provider's ServiceAccount | options for the provider's Deployment | `DeploymentRuntimeConfig` with `spec.serviceAccountTemplate` |
| Connect the two | the `Provider` | `spec.runtimeConfigRef.name` |
| Prove it works | status of the `Provider` | `INSTALLED` and `HEALTHY` in `kubectl get providers` |

## The feedback loop

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch -c sections/section-030/module-01/labs/lab-01
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

The grader has two checks: `provider-installed` and `provider-identity`. Both fail at the start, because no provider exists. The watch terminal shows each check as it turns green.

---

## Step 1: Look at the starting state

Check that Crossplane runs and that no provider exists:

```sh
kubectl -n crossplane-system get deployments
kubectl get providers
```

You see the Deployments `crossplane` and `crossplane-rbac-manager`. The second command lists no providers. No check turns green in this step.

---

## Step 2: Fix the ServiceAccount name

Crossplane gives the provider's ServiceAccount a generated name unless you set one. A `DeploymentRuntimeConfig` sets options for the provider's Deployment, including that name.

Save this as `deploymentruntimeconfig-provider-kubernetes.yaml`:

```yaml
apiVersion: pkg.crossplane.io/v1beta1
kind: DeploymentRuntimeConfig
metadata:
  name: provider-kubernetes
spec:
  serviceAccountTemplate:
    metadata:
      name: provider-kubernetes
```

- `kind: DeploymentRuntimeConfig` is the object that holds options for a provider's Deployment.
- `metadata.name` is the name that the `Provider` refers to in the next step.
- `serviceAccountTemplate.metadata.name` is the fixed name of the ServiceAccount that the provider pod uses.

Apply it:

```sh
kubectl apply -f deploymentruntimeconfig-provider-kubernetes.yaml
```

Check the watch terminal. No check turns green yet, because there is no provider.

---

## Step 3: Install the provider

Save this as `provider-kubernetes.yaml`:

```yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-kubernetes
spec:
  package: xpkg.crossplane.io/crossplane-contrib/provider-kubernetes:v1.4.1
  runtimeConfigRef:
    name: provider-kubernetes
```

- `spec.package` is the full image reference: registry, organisation, name and version tag. Keep the tag `v1.4.1`.
- `spec.runtimeConfigRef.name` points at the `DeploymentRuntimeConfig` from step 2.

Apply it:

```sh
kubectl apply -f provider-kubernetes.yaml
```

Crossplane now pulls the package from `xpkg.crossplane.io`. This takes from a few seconds to a few minutes.

---

## Step 4: Wait for the provider to become healthy

Wait for the `Healthy` condition and read the table:

```sh
kubectl wait provider.pkg.crossplane.io/provider-kubernetes --for=condition=Healthy --timeout=300s
kubectl get providers
```

The table shows `True` under `INSTALLED` and `HEALTHY` for `provider-kubernetes`. Check the pod and its ServiceAccount:

```sh
kubectl -n crossplane-system get pods
kubectl -n crossplane-system get serviceaccount provider-kubernetes
```

A `provider-kubernetes-...` pod is `Running`, and the ServiceAccount exists.

Check the watch terminal. The checks `provider-installed` and `provider-identity` now pass.

---

## Step 5: Submit

When both checks are green, press Ctrl-C to stop the watch and run the submit command once:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

---

## If a check stays red

- **`provider-installed` fails with "spec.package is ...".** The package tag is missing or different. Set the tag `v1.4.1` and apply the file again.
- **`provider-installed` fails with "Provider is not Healthy".** The package manager is still pulling the package, or the pod cannot start. Wait one minute and check the watch terminal again. Then read `kubectl describe provider.pkg.crossplane.io provider-kubernetes` and `kubectl -n crossplane-system get pods`. A cluster without outbound internet access cannot pull the package.
- **`provider-identity` fails with "no spec.runtimeConfigRef".** The `Provider` does not refer to your `DeploymentRuntimeConfig`. Add `runtimeConfigRef.name` and apply the file again.
- **`provider-identity` fails with "sets the ServiceAccount name to ...".** The `serviceAccountTemplate.metadata.name` is empty or has another value. It must be `provider-kubernetes`.
- **`provider-identity` fails and you edited the provider's Deployment by hand.** Crossplane owns that Deployment and puts the configuration back. Change the `DeploymentRuntimeConfig` instead.
