# Offer Self-Service Through Git And Scoped RBAC

A platform API is only self-service when a tenant team can use it without help from the platform team and without more rights than it needs. This module settles two questions. Who may create a `TeamEnvironment` request, and how does that request reach the cluster? The answer to the first is Role-Based Access Control (RBAC). The answer to the second is a Git repository that Argo CD watches.

A tenant that holds `cluster-admin` can do anything, so it can also break the platform. A tenant that holds no rights cannot ask for anything. The goal is the narrow case between them: the tenant creates and reads one kind of object in its own namespace, and nothing else.

The module has four parts. **Scope A Tenant With A Role And RoleBinding** gives the group `outpost-team` access to `TeamEnvironment` objects in `outpost` and proves the limits with `kubectl auth can-i`. **Aggregate Platform API Permissions Into edit And view** adds the same permissions to the built-in `edit` and `view` ClusterRoles with a label. **Deliver Requests Through Git With Argo CD** writes the `AppProject` and `Application` that turn a committed file into a cluster object. **Follow A Request From Commit To Ready** commits a request, then reads the Argo CD status and the composite resource status to find where a request stops.

## Learning objectives

After this module you can:

- Design a request flow where a tenant adds a composite resource manifest to a Git repository and Argo CD applies it.
- Write a Role and RoleBinding that let a tenant group create and read only the platform API kind in its own namespace.
- Aggregate the platform API's permissions into the built-in `edit` and `view` ClusterRoles with an aggregation label.
- Prove with `kubectl auth can-i --as` that the tenant can request a `TeamEnvironment` but cannot create Deployments or read Secrets.
- Trace a Git request through an Argo CD sync to a `Ready` composite resource.

## Before you start

You need Kubernetes basics: namespaces, Roles, `kubectl get` and `kubectl apply`. You also need to know what a composite resource is: an object of a platform API kind that Crossplane turns into other objects. The `TeamEnvironment` kind is one such platform API. A tenant creates one in a namespace, and Crossplane composes a Deployment and a Service from it.

Write each example file in a new, empty folder on your machine and run every command from that folder. Your playground runs Kubernetes 1.35.8, Crossplane 2.4.2 and Argo CD 3.5.4 in a single-node `kind` cluster. It needs outbound internet and takes longer to start than other playgrounds.

| Where | What is there |
| --- | --- |
| Crossplane | `provider-kubernetes`, `function-patch-and-transform`, and the `TeamEnvironment` XRD and Composition, all installed |
| Namespace `gitea` | An in-cluster Git server with the repository `starfleet/outpost-requests`, which holds an empty `requests/` folder |
| Namespace `argocd` | Argo CD, with one `Application` that watches that repository |
| Namespace `outpost` | The tenant namespace |
| Tenant identity | The user `outpost-dev` in the group `outpost-team`, which you impersonate with `kubectl --as`. It has no RBAC yet |

Gitea is only the Git server for the playground. You never learn its commands or web page: a Git server is where the request file is stored, and the lesson is about what Argo CD does with it.

Launch your playground now, and keep it running while you read:

<!-- astrona:playground -->
