# Solution Walkthrough

You build the platform API from the bottom up: the provider, its access, the API
definition, the Composition, and then the tenant request. You never create the Deployment
or the Service yourself. Crossplane creates them from the Composition.

| Goal | Where it lives | Command or object |
| --- | --- | --- |
| Install the provider | Crossplane package manager | `Provider`, `DeploymentRuntimeConfig` |
| Connect it to this cluster | Provider configuration | `ClusterProviderConfig` `in-cluster` |
| Let it manage workloads in `outpost` | RBAC in `outpost` | `Role`, `RoleBinding` |
| Define the API | Crossplane | `CompositeResourceDefinition` |
| Say what the API creates | Crossplane | `Composition` with `function-patch-and-transform` |
| Request and prove it | Tenant namespace | `TeamEnvironment`, then `curl` from `shuttle` |

## The feedback loop

Run this from the terminal where you typed `astrona run`, after every step:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

The checks are `provider`, `provider-rbac`, `xrd-definition`, `xrd-validation`,
`request-ready`, `answers`, `no-shortcuts` and `replicas-follow-request`. At the start,
most checks fail. Each step below says which checks it turns green.

---

## Step 1: Install the provider

The provider must run under a ServiceAccount with a fixed name, because the Role and the
RoleBinding in `outpost` already name `provider-kubernetes`. A `DeploymentRuntimeConfig`
sets that name. It also passes the argument `--poll=30s` to the provider container. The
provider uses this interval to read the live status of each `Object` again. Without it, the
default interval is ten minutes, and `status.availableReplicas` of the request stays old or
empty for a long time. Save this as `provider.yaml`:

```yaml
apiVersion: pkg.crossplane.io/v1beta1
kind: DeploymentRuntimeConfig
metadata:
  name: provider-kubernetes
spec:
  serviceAccountTemplate:
    metadata:
      name: provider-kubernetes
  deploymentTemplate:
    spec:
      selector: {}
      template:
        spec:
          containers:
            - name: package-runtime
              args:
                - --poll=30s
---
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-kubernetes
spec:
  package: xpkg.crossplane.io/crossplane-contrib/provider-kubernetes:v1.4.1
  runtimeConfigRef:
    name: provider-kubernetes
```

Apply it:

```sh
kubectl apply -f provider.yaml
```

Then wait for the provider and check its ServiceAccount:

```sh
kubectl wait provider.pkg.crossplane.io/provider-kubernetes --for=condition=Healthy --timeout=600s
kubectl get providers
kubectl -n crossplane-system get serviceaccount provider-kubernetes
```

Crossplane pulls the package from `xpkg.crossplane.io`, so this can take a few minutes. The
`Provider` shows `INSTALLED True` and `HEALTHY True` when it is ready. The check `provider`
is still red, because the ProviderConfig does not exist yet.

---

## Step 2: Connect the provider to this cluster

The provider installs the CRD for the `ClusterProviderConfig` when it becomes healthy.
Save this as `clusterproviderconfig-in-cluster.yaml`:

```yaml
apiVersion: kubernetes.m.crossplane.io/v1alpha1
kind: ClusterProviderConfig
metadata:
  name: in-cluster
spec:
  credentials:
    source: InjectedIdentity
```

Apply it:

```sh
kubectl apply -f clusterproviderconfig-in-cluster.yaml
```

`InjectedIdentity` means the provider uses the ServiceAccount of its own pod to call the
Kubernetes API server. **Run the check.** The check `provider` passes.

---

## Step 3: Complete the RBAC

Crossplane gives a provider access to its own CRDs only. Everything the provider creates
needs a Role that you write. Read what the platform team already started:

```sh
kubectl -n outpost get role provider-kubernetes-workloads -o yaml
kubectl -n outpost get rolebinding provider-kubernetes-workloads -o yaml
kubectl auth can-i create deployments.apps -n outpost --as=system:serviceaccount:crossplane-system:provider-kubernetes
kubectl auth can-i create services -n outpost --as=system:serviceaccount:crossplane-system:provider-kubernetes
```

The RoleBinding is correct: it gives the Role to the ServiceAccount `provider-kubernetes`
in `crossplane-system`. The Role covers Deployments only, so the last command prints `no`.
Save the complete Role as `role-provider-kubernetes-workloads.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: provider-kubernetes-workloads
  namespace: outpost
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

Apply it:

```sh
kubectl apply -f role-provider-kubernetes-workloads.yaml
```

A `Role` limits the permission to its own namespace. Do not use a `ClusterRole` with a
`ClusterRoleBinding` and do not use `cluster-admin`: the graders reject both.
**Run the check.** The check `provider-rbac` passes.

---

## Step 4: Define the API

Save this as `xrd-teamenvironment.yaml`:

```yaml
apiVersion: apiextensions.crossplane.io/v2
kind: CompositeResourceDefinition
metadata:
  name: teamenvironments.platform.starfleet.io
spec:
  scope: Namespaced
  group: platform.starfleet.io
  names:
    kind: TeamEnvironment
    plural: teamenvironments
  versions:
    - name: v1alpha1
      served: true
      referenceable: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                team:
                  type: string
                size:
                  type: string
                  enum: [small, medium, large]
                  default: small
                replicas:
                  type: integer
                  minimum: 1
                  maximum: 3
                  default: 1
                contact:
                  type: string
              required:
                - team
            status:
              type: object
              properties:
                availableReplicas:
                  type: integer
```

Apply it and wait until the XRD is established:

```sh
kubectl apply -f xrd-teamenvironment.yaml
kubectl wait xrd/teamenvironments.platform.starfleet.io --for=condition=Established --timeout=120s
```

Crossplane turns the XRD into a CRD. The schema declares every field, so the API server
refuses a request with no `team`, a `replicas` outside 1 to 3, a `size` that is not in the
enum, or an unknown field. The schema also declares `status.availableReplicas`, because the
API server drops a status field that the schema does not declare. Do not add
`x-kubernetes-preserve-unknown-fields`. **Run the check.** The checks `xrd-definition`
and `xrd-validation` pass.

---

## Step 5: Write the Composition

The Composition has one pipeline step. The function `function-patch-and-transform` creates
two `Object` resources, and its patches copy values between the request and the objects.
Save this as `composition-teamenvironment.yaml`:

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: teamenvironment
spec:
  compositeTypeRef:
    apiVersion: platform.starfleet.io/v1alpha1
    kind: TeamEnvironment
  mode: Pipeline
  pipeline:
    - step: patch-and-transform
      functionRef:
        name: function-patch-and-transform
      input:
        apiVersion: pt.fn.crossplane.io/v1beta1
        kind: Resources
        resources:
          - name: deployment
            base:
              apiVersion: kubernetes.m.crossplane.io/v1alpha1
              kind: Object
              spec:
                providerConfigRef:
                  kind: ClusterProviderConfig
                  name: in-cluster
                forProvider:
                  manifest:
                    apiVersion: apps/v1
                    kind: Deployment
                    metadata:
                      name: scout
                    spec:
                      replicas: 1
                      selector:
                        matchLabels:
                          app: scout
                      template:
                        metadata:
                          labels:
                            app: scout
                        spec:
                          containers:
                            - name: scout
                              image: ghcr.io/stefanprodan/podinfo:6.15.0
                              ports:
                                - containerPort: 9898
            patches:
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.namespace
                toFieldPath: spec.forProvider.manifest.metadata.namespace
              - type: FromCompositeFieldPath
                fromFieldPath: spec.replicas
                toFieldPath: spec.forProvider.manifest.spec.replicas
              - type: FromCompositeFieldPath
                fromFieldPath: spec.team
                toFieldPath: spec.forProvider.manifest.spec.template.metadata.labels.team
              - type: ToCompositeFieldPath
                fromFieldPath: status.atProvider.manifest.status.availableReplicas
                toFieldPath: status.availableReplicas
          - name: service
            base:
              apiVersion: kubernetes.m.crossplane.io/v1alpha1
              kind: Object
              spec:
                providerConfigRef:
                  kind: ClusterProviderConfig
                  name: in-cluster
                forProvider:
                  manifest:
                    apiVersion: v1
                    kind: Service
                    metadata:
                      name: scout
                    spec:
                      selector:
                        app: scout
                      ports:
                        - port: 9898
                          targetPort: 9898
            patches:
              - type: FromCompositeFieldPath
                fromFieldPath: metadata.namespace
                toFieldPath: spec.forProvider.manifest.metadata.namespace
```

Apply it:

```sh
kubectl apply -f composition-teamenvironment.yaml
```

Read the patches:

- `metadata.namespace` puts the Deployment and the Service in the namespace of the request.
- `spec.replicas` sets the replicas of the Deployment. A fixed number here fails the check
  `replicas-follow-request`.
- `spec.team` sets the pod label `team`.
- The `ToCompositeFieldPath` patch copies the available replicas of the Deployment from the
  status of the `Object` to `status.availableReplicas` of the request.

---

## Step 6: Request an environment

You act as the tenant now. Save this as `teamenvironment-scout-env.yaml`:

```yaml
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: scout-env
  namespace: outpost
spec:
  team: outpost
  size: medium
  replicas: 2
```

Apply it:

```sh
kubectl apply -f teamenvironment-scout-env.yaml
```

Then wait and read the result:

```sh
kubectl -n outpost wait teamenvironment/scout-env --for=condition=Ready --timeout=600s
kubectl -n outpost get teamenvironment scout-env
kubectl -n outpost get objects.kubernetes.m.crossplane.io
kubectl -n outpost get deployment,service scout
```

The request becomes `Synced` and `Ready`, the available replicas show `2`, and the two
`Object` resources and the `scout` Deployment and Service exist. If the request stays not
ready, trace it. Run `/workspace/bin/crossplane resource trace teamenvironment scout-env -n outpost`
and `kubectl -n outpost describe objects.kubernetes.m.crossplane.io`. A message that
contains `forbidden` names a missing RBAC rule (go back to Step 3). A message about a
ProviderConfig names a wrong `providerConfigRef` in the Composition.

The provider retries a failed `Object` with a growing delay. After you repair the cause,
wait one or two minutes before you look again.

---

## Step 7: Prove that the workload answers

Send a request from `shuttle` to the Service:

```sh
kubectl -n outpost exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://scout:9898
```

The command prints `200`. If it prints `000`, the pods are still starting. Run it again.
**Run the check.** The checks `request-ready`, `answers` and `no-shortcuts` pass, and so does
`replicas-follow-request`. That check changes `replicas` to 3 and back to 2 for a short time,
so wait for it to finish.

---

## Step 8: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

---

## If a check stays red

- **`provider` says the Provider is not Healthy.** The package is still downloading, or the
  package name has a typo. Read `kubectl describe provider.pkg.crossplane.io provider-kubernetes`.
- **`provider` says the pod runs under another ServiceAccount.** The `Provider` has no
  `runtimeConfigRef` to the `DeploymentRuntimeConfig`, or the name in the template differs.
- **`provider-rbac` says the provider cannot manage Services.** The Role has no rule for
  `services`. The rule needs `apiGroups: [""]`, not `["apps"]`.
- **`provider-rbac` says the provider can list in all namespaces, create Pods, or do
  everything.** You used a `ClusterRoleBinding`, `cluster-admin` or a wildcard. Remove it
  and keep the Role in `outpost`.
- **`xrd-validation` says the API server accepted a bad request.** The `minimum`, `maximum`
  or `enum` is missing, `team` is not in `required`, or the schema uses
  `x-kubernetes-preserve-unknown-fields`.
- **`request-ready` says `status.availableReplicas` is empty.** The status field is missing
  in the XRD schema, or the `ToCompositeFieldPath` patch is missing in the Composition.
- **`replicas-follow-request` says the Deployment did not follow.** The Composition sets a
  fixed number, or you scaled the Deployment by hand. Patch `spec.replicas` from the request.
- **`no-shortcuts` says the Objects are not the composed ones.** You created an `Object`,
  a Deployment or a Service by hand, or you added a second provider configuration. Delete
  it and fix the Composition instead.
