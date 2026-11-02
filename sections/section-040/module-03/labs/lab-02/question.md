# Question

Solve this question on: `terminal`

## Scenario

The `drifter` team in `outpost` asks for its environment by committing a file to the Git repository `starfleet/outpost-requests`. Argo CD should apply that file, and Crossplane should build the workload from it. Nothing arrives. The Application `outpost-requests` in the namespace `argocd` does not deliver the file, and the project `outpost` that guards it was written too narrowly. The platform team must fix both without opening the project to every kind, every namespace or every repository.

The Git server is reachable inside the cluster at `http://gitea-http.gitea.svc:3000`. From your machine, use `kubectl -n gitea port-forward svc/gitea-http 3000:3000`. The Git user is `platform` and the password is `platform-secret-19`.

## Tasks

1. **Fix the AppProject.** The AppProject `outpost` in `argocd` must allow exactly one namespaced kind: `TeamEnvironment` in the group `platform.starfleet.io`. It must keep one source repository, `http://gitea-http.gitea.svc:3000/starfleet/outpost-requests.git`, and one destination namespace, `outpost`. It must allow no cluster-scoped kind and use no wildcard.

2. **Fix the Application.** The Application `outpost-requests` must stay in the project `outpost`. It must read the folder `requests` of the same repository at `HEAD`, and write to the namespace `outpost` of the cluster `https://kubernetes.default.svc`. Argo CD must sync it by itself, with `prune` and `selfHeal` both set to `true`.

3. **Commit the request.** Commit the file `requests/drifter.yaml` to the repository. It holds one `TeamEnvironment` of the API `platform.starfleet.io/v1alpha1` with these values:

   | Field | Value |
   | --- | --- |
   | `metadata.name` | `drifter` |
   | `metadata.namespace` | `outpost` |
   | `spec.team` | `outpost` |
   | `spec.size` | `small` |
   | `spec.replicas` | `1` |
   | `spec.contact` | `drifter@outpost.starfleet.io` |

   Argo CD must create the `TeamEnvironment`. Do not apply the file with `kubectl`.

4. **Reach Ready.** The Application `outpost-requests` must be `Synced` and `Healthy`. The `TeamEnvironment` `drifter` must have the conditions `Synced` and `Ready` set to `True`. A request from the `shuttle` Deployment in `outpost` to `http://scout:9898` must return HTTP status `200`.
