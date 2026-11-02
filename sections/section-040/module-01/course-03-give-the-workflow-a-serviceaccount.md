# Give The Workflow A ServiceAccount

A step that prints text needs no permissions. A provisioning step creates a Deployment and a Service, and the Kubernetes API server allows that only for an identity with the right Role-based access control (RBAC) rules. This part shows which identity a step uses, what happens when its rules are too small, and how to read that failure.

## The step pod runs as a ServiceAccount

Every pod runs as a ServiceAccount. The ServiceAccount is the identity that the API server checks when a process in the pod calls the API. A Workflow sets it with `spec.serviceAccountName`. When the field is empty, the step pods use the `default` ServiceAccount of the namespace. That account is shared, so give each workflow its own.

The playground has the ServiceAccount `provisioner` in `starfleet`. The workflow pods run in `starfleet`, but the objects must appear in `outpost`. That needs permission in two places. Ask the API server what `provisioner` may do in `outpost`:

<!-- astrona:playground:renew -->

```sh
kubectl auth can-i create deployments.apps -n outpost --as=system:serviceaccount:starfleet:provisioner
```

You should see `no`. The option `--as` makes `kubectl` send the request as another identity. The name has the form `system:serviceaccount:<namespace>:<name>`. This check is the fastest way to test RBAC before you run a workflow.

## A resource step that applies the scout workload

A `resource` template applies a Kubernetes manifest from inside the workflow. Its field `action` is a `kubectl` action such as `create`, `apply`, `patch` or `delete`. The field `manifest` holds one object. One resource template manages only one object, so the Deployment and the Service need two steps.

Save this as `workflowtemplate-deploy-scout.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: WorkflowTemplate
metadata:
  name: deploy-scout
  namespace: starfleet
spec:
  entrypoint: deploy
  serviceAccountName: provisioner
  arguments:
    parameters:
      - name: namespace
        value: outpost
  templates:
    - name: deploy
      steps:
        - - name: scout-deployment
            template: apply-deployment
        - - name: scout-service
            template: apply-service
    - name: apply-deployment
      resource:
        action: apply
        manifest: |
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: scout
            namespace: {{workflow.parameters.namespace}}
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
    - name: apply-service
      resource:
        action: apply
        manifest: |
          apiVersion: v1
          kind: Service
          metadata:
            name: scout
            namespace: {{workflow.parameters.namespace}}
          spec:
            selector:
              app: scout
            ports:
              - port: 9898
                targetPort: 9898
```

The field `serviceAccountName` in the WorkflowTemplate spec sets the identity for every step pod. Apply it and submit a Workflow:

```sh
kubectl apply -f workflowtemplate-deploy-scout.yaml
argo -n starfleet submit --from workflowtemplate/deploy-scout --watch
```

You should see the Workflow end as `Failed`. The first step cannot create the Deployment.

## Find the failing step from status and logs

Do not guess. Read the Workflow in three steps: the phase, the node that failed, and the log of that node. First list the nodes with their phase:

```sh
kubectl -n starfleet get workflows -o jsonpath='{range .items[-1].status.nodes.*}{.displayName}{"\t"}{.phase}{"\t"}{.message}{"\n"}{end}'
```

You should see one line per node. The node `scout-deployment` has the phase `Failed`, and the node `scout-service` does not appear because the step never started. The `message` of a failed node gives a short reason, and the whole Workflow also has `status.message`. Read the log of the failed step for the full text:

```sh
kubectl -n starfleet logs -l workflows.argoproj.io/workflow -c main
```

You should see an error from the API server with the word `forbidden`. It names the user `system:serviceaccount:starfleet:provisioner`, the verb and the resource, and the namespace `outpost`. This is the line to read in the exam: it tells you who was refused, what they tried and where. If more than one Workflow exists, add the name of the failed Workflow to the label selector.

## Grant only what the steps need

The fix is a Role in `outpost` that lists exactly the verbs the steps use, and a RoleBinding that gives the Role to the ServiceAccount in `starfleet`. A resource step with `action: apply` reads, creates and patches the object. Save this as `role-provisioner-outpost.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: provisioner-scout
  namespace: outpost
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "create", "patch"]
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get", "create", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: provisioner-scout
  namespace: outpost
subjects:
  - kind: ServiceAccount
    name: provisioner
    namespace: starfleet
roleRef:
  kind: Role
  name: provisioner-scout
  apiGroup: rbac.authorization.k8s.io
```

Apply it:

```sh
kubectl apply -f role-provisioner-outpost.yaml
```

The step pods also report their result to the controller. In Argo Workflows 4.x the executor does that by writing a `WorkflowTaskResult` object in the namespace of the Workflow. The ServiceAccount therefore needs the verbs `create` and `patch` on `workflowtaskresults` in `starfleet`. If the playground did not give it those verbs, the step runs but the Workflow reports an error when the pod ends. The log of the `wait` container shows the `forbidden` message. Check it:

```sh
kubectl auth can-i create workflowtaskresults.argoproj.io -n starfleet --as=system:serviceaccount:starfleet:provisioner
```

If the answer is `no`, save this as `role-provisioner-taskresults.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: provisioner-taskresults
  namespace: starfleet
rules:
  - apiGroups: ["argoproj.io"]
    resources: ["workflowtaskresults"]
    verbs: ["create", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: provisioner-taskresults
  namespace: starfleet
subjects:
  - kind: ServiceAccount
    name: provisioner
    namespace: starfleet
roleRef:
  kind: Role
  name: provisioner-taskresults
  apiGroup: rbac.authorization.k8s.io
```

Apply it with `kubectl apply -f role-provisioner-taskresults.yaml`. Then run the workflow again and check the workload:

```sh
argo -n starfleet submit --from workflowtemplate/deploy-scout --watch
kubectl -n outpost get deployment,service scout
```

You should see the Workflow end as `Succeeded`, and the Deployment and the Service `scout` in `outpost`.

Two wrong fixes work but break the purpose. Binding `cluster-admin` to `provisioner` gives a provisioning workflow power over the whole cluster. Giving the verb `*` on `*` does the same. Name the resources and verbs the steps use, and nothing more.

You now know which identity a step pod uses, how to prove its permissions with `kubectl auth can-i --as`, and how to follow a `Failed` Workflow from the phase to the node to the pod log. The scout workload is created, but a provisioning flow must also create the platform API object and wait until it is ready.

## Common pitfalls

> [!WARNING]
> - **Granting permission in the wrong namespace.** The pod runs in `starfleet`, but the Role for the scout objects must be in `outpost`.
> - **Forgetting the RoleBinding subject namespace.** A ServiceAccount subject needs `namespace: starfleet`.
> - **Fixing a permission error with `cluster-admin`.** It hides the real rule and gives the workflow too much power.
> - **Reading only `kubectl get workflows`.** The table shows `Failed`. The reason is in the node message and the pod log.

## Your mission: Fix A Provisioning Workflow That Fails On Permissions

You can now find a permission failure in a Workflow and fix it with a narrow Role. The mission gives you a workflow whose steps fail with `forbidden`, and asks you to make it succeed without using `cluster-admin`.

Pause the playground first:

```sh
astrona stop ats-019-playground-040-01
```

Start the lab and submit your work when you are ready:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-01/labs/lab-02
astrona submit -c sections/section-040/module-01/labs/lab-02
```

When you are done, remove the lab and start the playground again:

```sh
astrona destroy ats-019-lab-040-01-02
astrona start ats-019-playground-040-01
```
