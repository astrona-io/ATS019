# Overview: Offer Self-Service Through Git And Scoped RBAC (Playground)

This playground gives you a working platform API, a Git server and Argo CD, so you can scope a tenant with Role-Based Access Control (RBAC) and deliver a request through Git. There is nothing to submit and no grading.

## What's in the box

The single-node `kind` cluster runs Kubernetes 1.35.8. It needs outbound internet access and takes several minutes to start.

| Where | What is there |
| --- | --- |
| Namespace `crossplane-system` | Crossplane 2.4.2, `provider-kubernetes` 1.4.1 and `function-patch-and-transform` 0.11.0 |
| Cluster | The `TeamEnvironment` XRD (`platform.starfleet.io/v1alpha1`) and the Composition `teamenvironment`, which creates a `scout` Deployment and Service in the namespace of the request |
| Namespace `gitea` | Gitea, an in-cluster Git server, with the public repository `starfleet/outpost-requests` and an empty `requests/` folder |
| Namespace `argocd` | Argo CD 3.5.4 and the Application `outpost-requests` in the `default` project, with no automated sync |
| Namespace `outpost` | The tenant namespace, the client Deployment `shuttle`, and a Role and RoleBinding that let `provider-kubernetes` manage Deployments and Services here |
| Namespace `starfleet` | The platform team namespace, empty |

The tenant identity is the user `outpost-dev` in the group `outpost-team`. It has no RBAC. You test it with `kubectl --as outpost-dev --as-group outpost-team`; your own administrator account may impersonate.

Gitea is only the Git server. The user is `platform`, the password is `platform-secret-19`, and the Secret `gitea-platform` in namespace `gitea` holds both. Reach the server from your machine with `kubectl -n gitea port-forward svc/gitea-http 3000:3000`, then use `http://platform:platform-secret-19@127.0.0.1:3000/starfleet/outpost-requests.git`.

Both composed objects are named `scout`, so the Composition supports one `TeamEnvironment` per namespace.

## Practice tasks

- Ask `kubectl auth can-i` whether `outpost-dev` can create a `TeamEnvironment`. Give the group a Role and RoleBinding, then check an allowed action, a denied action and a second namespace.
- Add a ClusterRole with the label `rbac.authorization.k8s.io/aggregate-to-view: "true"` and read the rules of the built-in `view` ClusterRole.
- Write an AppProject for `outpost` that allows one repository, one namespace and one kind. Move the Application into it and turn on automated sync with `prune` and `selfHeal`.
- Commit a `TeamEnvironment` to `requests/`, refresh the Application, and follow the request until the composite resource is `Ready`.
- Commit a request with `size: huge`, and a file that names another namespace. Read the Application status for each refusal.
- Delete the request file from Git and check that Argo CD removes the `TeamEnvironment` and what Crossplane built from it.
