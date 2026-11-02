# Summary

Self-service on a platform means that a tenant asks for what it needs through a platform API and holds no other rights. The tenant creates a `TeamEnvironment`. The platform controller, running as a different identity, creates the Deployment and Service. A Role and a RoleBinding in the tenant namespace give the tenant group the verbs it needs on one resource, and nothing more.

RBAC is proven by asking, not by reading. The command `kubectl auth can-i` with `--as` and `--as-group` shows what an identity may do. A correct check covers the allowed action, a denied action and a second namespace. Binding `cluster-admin`, or the built-in `edit` role, to a tenant fails these checks, because both can read Secrets.

An aggregation label extends the built-in roles when the platform adds a kind. A ClusterRole with `rbac.authorization.k8s.io/aggregate-to-edit: "true"` or `aggregate-to-view: "true"` adds its rules to `edit` or `view`. This suits the platform's own users. Tenants keep the narrow Role.

A request can also be a file in Git. Argo CD reads the repository and applies the file with its own identity, so the tenant needs access to the repository and not to the cluster. An `AppProject` limits the repositories, destinations and resource kinds. An `Application` names the source and destination, and `syncPolicy.automated` with `prune` and `selfHeal` keeps the cluster equal to Git.

A request has two statuses. The Application status, `Synced` and `Healthy`, says whether the file reached the cluster. The composite resource conditions, `Synced` and `Ready`, say whether Crossplane built the environment. Read the first, then the second, to find where a request stopped.

Key facts:

- A RoleBinding grants rights only in its own namespace.
- An unquoted `true` in an aggregation label is a YAML boolean and Kubernetes rejects it.
- `prune: true` deletes a cluster object when its file leaves Git.
- `selfHeal: true` reverts changes made directly in the cluster.
- An `Application` in the `default` project can use any repository, namespace and kind.

<!-- astrona:playground:destroy -->
