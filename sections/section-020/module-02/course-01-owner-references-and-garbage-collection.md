# Owner References And The Garbage Collector

A `Prometheus` custom resource asks for a server, but several objects must exist to run it. A CustomResourceDefinition (CRD) adds a resource type to the Kubernetes application programming interface (API). A custom resource is one object of that type.

A controller is a program that watches objects and changes the cluster to match their desired state. The Prometheus Operator packages a controller with CRDs to create and manage a Prometheus server. Before deleting the request, read the ownership links to see what else will go.

## Read the ownership chain

An owner reference is an entry in `metadata.ownerReferences` that links a dependent object to its owner. It holds the owner's kind, name and unique identifier (UID). A StatefulSet manages pods with stable names, a Service provides a network endpoint, and a Secret stores data such as credentials or generated configuration.

<!-- astrona:playground:renew -->

List these objects and their owners in `starfleet`:

```sh
kubectl -n starfleet get statefulset,service,secret -o custom-columns='KIND:.kind,NAME:.metadata.name,OWNER:.metadata.ownerReferences[*].name,CONTROLLER:.metadata.ownerReferences[*].controller'
```

You should see:

```text
KIND          NAME                                                      OWNER       CONTROLLER
StatefulSet   prometheus-starfleet                                      starfleet   true
Service       prometheus-operated                                       starfleet   <none>
Secret        prometheus-starfleet                                      starfleet   true
Secret        prometheus-starfleet-thanos-prometheus-http-client-file   starfleet   true
Secret        prometheus-starfleet-tls-assets-0                         starfleet   true
Secret        prometheus-starfleet-web-config                           starfleet   true
```

The resource `starfleet` owns one StatefulSet, one Service and four Secrets. `controller: true` marks the reference to the controller's owner object. An object can have several owners but at most one reference with `controller: true`. The Service has an owner but does not set that controller field.

Read the pod's owner as well:

```sh
kubectl -n starfleet get pod prometheus-starfleet-0 -o jsonpath='{.metadata.ownerReferences[0].kind}{"/"}{.metadata.ownerReferences[0].name}{"\n"}'
```

You should see:

```text
StatefulSet/prometheus-starfleet
```

The Prometheus Operator creates the StatefulSet. The built-in StatefulSet controller creates the pod. The pod therefore points to the StatefulSet, not directly to the `Prometheus` resource. Deletion can follow this chain down through several levels.

## Give a custom resource a dependent

A ConfigMap stores non-secret configuration as key-value data. You will create two ConfigMaps with the same label, but give only one an owner reference. A label is metadata used to select objects; it does not make Kubernetes delete one object when another goes.

The playground already has the `TeamEnvironment` CRD. No operator watches it. Save this as `teamenvironment-scout-env.yaml`:

```yaml
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: scout-env
  namespace: outpost
spec:
  team: outpost
  size: small
```

Apply it:

```sh
kubectl apply -f teamenvironment-scout-env.yaml
```

You should see:

```text
teamenvironment.platform.starfleet.io/scout-env created
```

Then read its UID and keep it in a shell variable:

```sh
TEAM_ENV_UID=$(kubectl -n outpost get teamenvironment scout-env -o jsonpath='{.metadata.uid}')
echo "$TEAM_ENV_UID"
```

You should see:

```text
9538472a-191e-438b-867e-9fd90b171762
```

Your UID differs. Replace `<TEAM_ENV_UID>` in the following manifest with the value you just printed. The UID identifies this exact owner, not every future object with the same name. Save this as `configmap-scout-owned.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: scout-owned
  namespace: outpost
  labels:
    team: outpost
  ownerReferences:
    - apiVersion: platform.starfleet.io/v1alpha1
      kind: TeamEnvironment
      name: scout-env
      uid: <TEAM_ENV_UID>
      blockOwnerDeletion: true
data:
  mode: small
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: scout-unowned
  namespace: outpost
  labels:
    team: outpost
data:
  mode: small
```

Apply it:

```sh
kubectl apply -f configmap-scout-owned.yaml
```

You should see:

```text
configmap/scout-owned created
configmap/scout-unowned created
```

Then check the result:

```sh
kubectl -n outpost get configmap -l team=outpost -o custom-columns='NAME:.metadata.name,OWNER:.metadata.ownerReferences[*].name,UID:.metadata.ownerReferences[*].uid'
```

You should see:

```text
NAME            OWNER       UID
scout-owned     scout-env   9538472a-191e-438b-867e-9fd90b171762
scout-unowned   <none>      <none>
```

Both objects have `team: outpost`, but only `scout-owned` points to `scout-env`. The reference omits `controller: true` because no application controller manages this ConfigMap. It sets `blockOwnerDeletion: true` so this dependent can block foreground deletion of its owner.

## Let Kubernetes remove the dependent

The garbage collector is a Kubernetes controller that deletes objects whose owners are gone. It uses owner references, not labels or names alone. Request background deletion, then wait for the owned ConfigMap to disappear:

```sh
kubectl -n outpost delete teamenvironment scout-env --cascade=background
kubectl -n outpost wait --for=delete configmap/scout-owned --timeout=60s
kubectl -n outpost get configmap -l team=outpost -o name
```

You should see:

```text
teamenvironment.platform.starfleet.io "scout-env" deleted from outpost namespace
configmap/scout-unowned
```

Only `scout-unowned` remains. The garbage collector removed the dependent even though no `TeamEnvironment` operator exists. Ownership records a lifecycle relationship; it does not install a controller or create dependent objects for you.

The wait command prints nothing if the dependent is already gone when it starts. If deletion is still running, it waits for that object to disappear before the final check.

A namespaced owner and its namespaced dependent must be in the same namespace. A namespaced dependent may also have a cluster-scoped owner. A cluster-scoped dependent cannot have a namespaced owner. If an object has several valid owners, losing just one does not normally remove the dependent while another owner remains.

You can now follow an operator's ownership chain and predict which objects disappear with a custom resource. The example also proved that labels do not control garbage collection. The remaining decision is whether the owner should wait for dependents or leave them behind.

## Common pitfalls

> [!WARNING]
> - **Matching the owner by name alone.** A recreated owner has a new UID. Read the UID from the object you actually created.
> - **Using a label as ownership.** A shared label helps you list objects but does not cause cascading deletion.
> - **Putting a namespaced owner in another namespace.** Kubernetes does not allow that ownership relationship.
> - **Expecting an owner reference to create resources.** It only records ownership; a controller or a person must create the objects.
