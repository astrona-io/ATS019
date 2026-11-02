# Deliver Requests Through Git With Argo CD

A tenant that can run `kubectl create` against the cluster needs credentials for it. A tenant that commits a file to a Git repository needs only access to that repository. Argo CD reads the repository and applies the file with its own identity. This part builds the path from file to cluster object and limits what a file in that repository may do.

## The request is a file

A request is one YAML file in the `requests/` folder of the repository `outpost-requests`. The playground hosts that repository on an in-cluster Git server at `http://gitea-http.gitea.svc:3000`, under the organisation `starfleet`. The server is plumbing: it stores files, and the lesson uses it only as the place Argo CD reads from.

The file holds a normal `TeamEnvironment`, the same object a tenant would apply with `kubectl`. Here is one for the `scout` workload. The field names come from the platform API's schema:

```yaml
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: drifter
  namespace: outpost
spec:
  team: outpost
  size: small
  replicas: 1
  contact: drifter@outpost.starfleet.io
```

Do not apply this file yet. The next sections build the Argo CD side first, so the commit has somewhere to land.

## Limit the sources and destinations with an AppProject

An Argo CD `AppProject` is a boundary for applications. It lists which Git repositories an application may read, which clusters and namespaces it may write to, and which resource kinds it may create. An `Application` always belongs to one project. The project `default` allows everything, so a tenant project must replace it.

<!-- astrona:playground:renew -->

Save this as `appproject-outpost.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: outpost
  namespace: argocd
spec:
  description: Requests from the outpost team
  sourceRepos:
    - http://gitea-http.gitea.svc:3000/starfleet/outpost-requests.git
  destinations:
    - server: https://kubernetes.default.svc
      namespace: outpost
  namespaceResourceWhitelist:
    - group: platform.starfleet.io
      kind: TeamEnvironment
```

The field `sourceRepos` allows one repository. The field `destinations` allows one namespace on the cluster that Argo CD runs in; `https://kubernetes.default.svc` is the in-cluster API server address. The field `namespaceResourceWhitelist` allows one namespaced kind. No `clusterResourceWhitelist` is set, so the project may create no cluster-scoped resource such as a Namespace or ClusterRole. This is what stops a request file from granting itself more rights.

Apply it:

```sh
kubectl apply -f appproject-outpost.yaml
```

## Write the Application

An `Application` connects a source in Git to a destination in the cluster. Its `syncPolicy` says whether Argo CD applies changes by itself. Save this as `application-outpost-requests.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: outpost-requests
  namespace: argocd
spec:
  project: outpost
  source:
    repoURL: http://gitea-http.gitea.svc:3000/starfleet/outpost-requests.git
    targetRevision: HEAD
    path: requests
  destination:
    server: https://kubernetes.default.svc
    namespace: outpost
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

The playground already has an Application with this name, so applying the file replaces its `spec` and moves it into the `outpost` project. In `source`, `repoURL`, `targetRevision` and `path` say which commit and folder Argo CD reads. In `destination`, `server` and `namespace` say where the objects go.

With `automated`, Argo CD syncs when it sees a new commit. With `prune: true`, it deletes a cluster object when its file leaves Git, so removing a request file removes the request. With `selfHeal: true`, it reverts a change made directly in the cluster, so Git stays the single source of truth.

Apply it:

```sh
kubectl apply -f application-outpost-requests.yaml
```

Then check the Application:

```sh
kubectl -n argocd get application outpost-requests
```

You should see the columns `SYNC STATUS` and `HEALTH STATUS`. The folder is empty, so Argo CD has nothing to apply. The status shows `Synced` when the cluster matches Git, and `Healthy` when the objects it applied are working.

The path from Git to the cluster now exists and has a boundary. The question still open is what a real request does on this path, and where to look when it stops.

## Common pitfalls

> [!WARNING]
> - **Leaving the Application in the `default` project.** That project allows any repository, any namespace and any kind. A request file could then create anything.
> - **Expecting `prune: true` to be harmless.** When a file is deleted from Git, the object is deleted from the cluster, and Crossplane removes what it composed.
> - **Putting the namespace only in the Application.** Argo CD applies the namespace in each file's `metadata`. The project's `destinations` check fails when a file names another namespace.
> - **Using `https://kubernetes.default.svc` for another cluster.** That address means the cluster Argo CD runs in.
