# Solution Walkthrough

You will read why the Application cannot deliver, fix the Application and the AppProject, commit the request file, and follow it to `Ready`. Everything happens in `argocd`, in the Git repository and in `outpost`. The Crossplane platform stays untouched.

| Goal | Where it lives | Command or file |
| --- | --- | --- |
| Why the file does not arrive | Application status | `kubectl -n argocd get application outpost-requests -o jsonpath=...` |
| What the project allows | AppProject `outpost` | `namespaceResourceWhitelist` |
| How the file is read and applied | Application `outpost-requests` | `source.path`, `syncPolicy.automated` |
| The request itself | Git repository | `requests/drifter.yaml` |
| Where the request stops | Application, then the composite resource | `kubectl ... get`, `describe` |

## The feedback loop

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-03/labs/lab-02
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

The watch terminal prints `PASS` or `FAIL` for each check. At the start, almost every check fails.

---

## Step 1: Read the Application status

Print the sync status and the conditions:

```sh
kubectl -n argocd get application outpost-requests
kubectl -n argocd get application outpost-requests -o jsonpath='{.status.conditions}{"\n"}'
```

The conditions report a comparison error. Its message says that the path `request` does not exist in the repository. The Application names a folder that is not there; the folder is `requests`. No check turns green in this step.

---

## Step 2: Fix the Application

Save this as `application-outpost-requests.yaml`:

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

The `path` is now `requests`. The `syncPolicy.automated` block makes Argo CD sync by itself. The field `project` stays `outpost`. Do not move the Application to the project `default`: it would work, but that project allows every kind. Apply it:

```sh
kubectl apply -f application-outpost-requests.yaml
```

The watch terminal shows the Application checks passing.

---

## Step 3: Fix the AppProject

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

The field `namespaceResourceWhitelist` was allowing only `ConfigMap`. It now allows only `TeamEnvironment`. There is no `clusterResourceWhitelist`, so no cluster-scoped kind is allowed. Do not use `group: "*"` and `kind: "*"`. Apply it:

```sh
kubectl apply -f appproject-outpost.yaml
```

The watch terminal shows the project check passing.

---

## Step 4: Commit the request

Start the port-forward and leave it running in another terminal:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

In the first terminal, clone the repository:

```sh
git clone http://platform:platform-secret-19@127.0.0.1:3000/starfleet/outpost-requests.git
```

Save this as `requests/drifter.yaml` inside the clone:

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

Commit and push it:

```sh
cd outpost-requests
git add requests/drifter.yaml
git commit -m "Request environment for drifter"
git push
```

The watch terminal shows the check that the file is committed passing.

---

## Step 5: Follow the request

Argo CD polls the repository about every three minutes. Ask it to look now:

```sh
kubectl -n argocd annotate application outpost-requests argocd.argoproj.io/refresh=hard --overwrite
kubectl -n argocd get application outpost-requests -o jsonpath='sync={.status.sync.status} health={.status.health.status}{"\n"}'
```

When the sync status is `Synced`, check the composite resource and the workload:

```sh
kubectl -n outpost get teamenvironment drifter
kubectl -n outpost get deployment,service
kubectl -n outpost exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://scout:9898
```

The `TeamEnvironment` shows `True` under `SYNCED` and `READY` after a short wait. The request prints `200`. The watch terminal shows the Argo CD, composite resource and workload checks passing.

---

## Step 6: Submit

When every check shows `PASS`, press Ctrl-C to stop the watch and run the submit command once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-03/labs/lab-02
```

---

## If a check stays red

- **The project check fails.** The `namespaceResourceWhitelist` does not list exactly `platform.starfleet.io` and `TeamEnvironment`, or a `clusterResourceWhitelist` exists. Allow one kind, no wildcard.
- **The Application check fails on the project.** You moved the Application to `default`. Set `project: outpost` again and fix the AppProject instead.
- **The Application stays `OutOfSync`.** Read the conditions and the sync result with `-o jsonpath='{.status.conditions}{"\n"}{.status.operationState.message}{"\n"}'`. A message that names a project means the AppProject refuses a kind, a namespace or the repository.
- **The delivered check fails but the object exists.** You applied the file with `kubectl`. Delete the object, then let Argo CD create it from Git. A `selfHeal` Application restores objects it owns.
- **The file is not committed.** The path must be `requests/drifter.yaml` on the default branch. Run `git push` again and read its output.
- **`Ready` stays `False`.** Run `kubectl -n outpost describe teamenvironment drifter` and read the conditions. The packages can take a minute to settle after a new request.
- **The 200 check fails.** Wait until `kubectl -n outpost get deployment scout` shows `1/1`, then check the watch terminal again.
