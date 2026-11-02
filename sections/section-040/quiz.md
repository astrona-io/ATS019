# Section 040 Knowledge Check: Self-Service Provisioning Workflows

## Coverage

- Write a WorkflowTemplate with input parameters, steps and a DAG of dependent tasks
- Submit a Workflow from a WorkflowTemplate with the argo CLI and override a parameter
- Give a workflow a ServiceAccount with only the RBAC its steps need, and diagnose a step that fails on permissions
- Read a workflow's phase, node status and step logs to find the failing step
- Use a resource template step to create a custom resource and wait for a success condition
- Install an EventBus and a webhook EventSource and send it an event with curl from shuttle
- Write a Sensor with a dependency and a trigger that submits a Workflow from a WorkflowTemplate
- Pass a value from the event payload into a workflow parameter
- Diagnose an event that does not start a workflow by reading EventSource and Sensor logs and status
- Design a request flow where a tenant adds a composite resource manifest to a Git repository and Argo CD applies it
- Write a Role and RoleBinding that let a tenant group create and read only the platform API kind in its own namespace
- Aggregate the platform API's permissions into the built-in edit and view ClusterRoles with an aggregation label
- Prove the tenant can request a TeamEnvironment but cannot create Deployments or read Secrets, with kubectl auth can-i --as
- Trace a Git request through Argo CD sync to a Ready composite resource

## Questions

Each question has one best answer.

### Question 1

You run `kubectl apply -f workflowtemplate-provision-environment.yaml` in the namespace `starfleet`. The command succeeds, but no pod appears. What is the reason?

- A. The workflow controller runs a WorkflowTemplate only after you restart it.
- B. A WorkflowTemplate only stores a definition. A Workflow that uses `workflowTemplateRef`, or `argo submit --from workflowtemplate/<name>`, starts a run.
- C. A WorkflowTemplate needs a `generateName` field before it can run.
- D. The WorkflowTemplate must be created in the namespace `argo`.

**Answer:** B

**Explanation:** A WorkflowTemplate has the same `spec` as a Workflow, but creating it runs nothing. Each run is a normal Workflow object that points at the template.

### Question 2

A WorkflowTemplate has two parameters in `spec.arguments.parameters`: `team` with the default `outpost` and `replicas` with the default `"1"`. You submit a Workflow with `workflowTemplateRef` and only this argument: `replicas` with the value `"2"`. Which values does the run use?

- A. `team` is `outpost` and `replicas` is `2`.
- B. `team` is empty and `replicas` is `2`.
- C. `team` is `outpost` and `replicas` is `1`.
- D. The Workflow is refused, because it must set every parameter.

**Answer:** A

**Explanation:** The values in the Workflow are merged with the defaults of the template, and the Workflow wins. The parameter `replicas` is overridden, and `team` keeps its default. The same override works on the command line with `argo submit --from workflowtemplate/<name> -p replicas=2`.

### Question 3

A provisioning flow has two checks, `validate-team` and `validate-size`, that do not depend on each other. A task called `create` must start only after both checks finish. Which design does this?

- A. A `steps` template with `create` in the first stage and the two checks in the second stage.
- B. A `steps` template with each task in its own stage, so all three run at the same time.
- C. A `dag` template where `create` has `dependencies: [validate-team, validate-size]`.
- D. Two Workflows that run one after the other.

**Answer:** C

**Explanation:** In a `dag` template, a task starts when all tasks it names in `dependencies` are done. The two checks have no dependencies, so they start together. In a `steps` template, each outer list item is a stage that runs in order, and only steps in the same stage run at the same time.

### Question 4

The steps of a Workflow create a Deployment in the namespace `outpost`. The Workflow runs in `starfleet` and does not set `spec.serviceAccountName`. Which identity does the API server check for the step pods?

- A. The `default` ServiceAccount of the namespace `starfleet`.
- B. The user who ran `kubectl create`.
- C. The ServiceAccount of the workflow controller in the namespace `argo`.
- D. The `default` ServiceAccount of the namespace `outpost`.

**Answer:** A

**Explanation:** A pod runs as a ServiceAccount. When the field is empty, the step pods use the `default` ServiceAccount of the namespace where the pod runs. That account is shared, so give each workflow its own ServiceAccount and a narrow Role.

### Question 5

A Workflow runs as the ServiceAccount `provisioner` in `starfleet` and ends as `Failed`. The log of the `main` container says that `system:serviceaccount:starfleet:provisioner` cannot create `deployments.apps` in the namespace `outpost`. Which fix is correct and narrow?

- A. Bind `cluster-admin` to `provisioner`.
- B. Create a Role in `starfleet` that allows `*` on `*`.
- C. Create a Role in `outpost` for the resources and verbs the steps use, and bind it to the ServiceAccount `provisioner` in `starfleet`.
- D. Run the Workflow again as the `default` ServiceAccount of `outpost`.

**Answer:** C

**Explanation:** The objects are created in `outpost`, so the Role must be in `outpost`. The RoleBinding subject names the ServiceAccount with `namespace: starfleet`. Options A and B work but give a provisioning workflow far more power than it needs. To find the fault, read the Workflow phase, then the failed node and its message, then the `main` log. The command `kubectl auth can-i ... --as=system:serviceaccount:starfleet:provisioner` proves the fix.

### Question 6

A Workflow has one `resource` step with `action: create` and `successCondition: status.phase == Ready`. The step created the `TeamEnvironment`. The Workflow stays in the phase `Running` with no error for several minutes. Which explanation is most likely?

- A. The step is waiting for the object to report `status.phase: Ready`, and nothing has set it yet.
- B. The ServiceAccount is missing the verb `delete`, so the step cannot finish.
- C. A `successCondition` makes the step run `kubectl create` again every minute.
- D. A `resource` step always ends after the object is created, so the Workflow is stuck in the controller.

**Answer:** A

**Explanation:** With a `successCondition`, the step watches the object and ends when the expression is true. A `failureCondition` ends it as failed. The wait has no timeout unless you set `activeDeadlineSeconds`. The step also needs `get`, `list` and `watch` on the object to see the change. When a Workflow does not move, read the status of the object that the step watches.

### Question 7

A tenant sends a JSON request to a webhook. Which statement describes the roles of the Argo Events objects correctly?

- A. The EventBus receives the HTTP request and the Sensor creates the Workflow.
- B. The EventSource receives the HTTP request and publishes the event to the EventBus. The Sensor reads the event from the EventBus and runs the trigger that creates the Workflow.
- C. The EventSource reads the event from the EventBus and the workflow controller creates the Workflow.
- D. The Sensor receives the HTTP request and the EventBus runs the trigger.

**Answer:** B

**Explanation:** The EventSource runs the HTTP server, and the EventBus carries events inside the namespace. The Sensor pod runs the trigger and creates the Workflow object with its own ServiceAccount. The Argo Workflows controller only runs the Workflow after it exists.

### Question 8

A webhook EventSource named `provision` has a webhook named `request` on the endpoint `/provision`. A client posts a valid request and gets `200`, but no Workflow appears. The Sensor log says that the ServiceAccount `operate-workflow-sa` cannot create `workflows` in the API group `argoproj.io`. What is the correct fix?

- A. Add a `service` block to the EventSource.
- B. Create a Role in `starfleet` that allows `create` on `workflows` (and read verbs if wanted), and bind it to `operate-workflow-sa`.
- C. Change `eventName` in the Sensor to `provision`.
- D. Bind `cluster-admin` to `operate-workflow-sa`.

**Answer:** B

**Explanation:** The Sensor pod creates the Workflow, so its ServiceAccount needs `create` on `workflows`. The `200` proves only that the EventSource accepted the request. Option D fixes the error but grants far more than the trigger needs. Send a new event after the fix, because the failed event does not run again.

### Question 9

A Sensor dependency has a data filter with `path: body.tier`, `type: string` and the values `standard` and `premium`. A client posts `{"team":"drifter","tier":"trial"}` with the header `Content-Type: application/json`. What happens?

- A. The EventSource returns `200`, the Sensor drops the event, and no Workflow starts.
- B. The EventSource returns an error status, because the tier is not allowed.
- C. The Sensor starts a Workflow, and the filter only changes its name.
- D. The EventBus rejects the event and the client sees `404`.

**Answer:** A

**Explanation:** The EventSource accepts any valid request on its endpoint and publishes it. The Sensor applies the filter and drops the event, so no trigger runs. The caller gets no error. Only the missing Workflow, and the Sensor log, show the drop.

### Question 10

A Sensor starts a Workflow whose first argument is the parameter `team`. You want the value of `team` to come from the posted JSON field `team`. Which trigger parameter does this?

- A. `src: {dependencyName: request-dep, dataKey: team}` with `dest: spec.arguments.parameters.team`
- B. `src: {dependencyName: request-dep, dataKey: body.team}` with `dest: spec.arguments.parameters.0.value`
- C. `src: {dependencyName: request-dep, dataKey: header.team}` with `dest: spec.arguments.parameters.1.value`
- D. `src: {dependencyName: request-dep, dataKey: body}` with `dest: spec.arguments.team`

**Answer:** B

**Explanation:** Webhook event data has `header` and `body`, so a posted JSON field starts with `body.`. The `dest` is a dotted path into the trigger resource, and list positions count from zero, so the first parameter is `parameters.0`. The request must carry `Content-Type: application/json`, or the body is not parsed as JSON.

### Question 11

A client posts to the webhook and gets `200`. The EventSource log shows the published event. The Sensor log shows no event and no trigger error, and no Workflow appears. The Sensor dependency has `eventName: requests`, but the EventSource webhook is named `request`. Which statement is correct?

- A. The fault is in the permissions of the Sensor ServiceAccount.
- B. The fault is in the WorkflowTemplate.
- C. The EventBus is missing.
- D. The Sensor waits for an event that no EventSource publishes, so it never sees the event. Set `eventName: request`.

**Answer:** D

**Explanation:** The `eventSourceName` and `eventName` of a dependency must match the EventSource name and the name under `webhook` exactly. Follow the path of the event in order: the request status, the EventSource status and log, the Sensor status and log, and last the Workflow. The first component whose evidence does not match its job holds the fault.

### Question 12

The group `outpost-team` has a RoleBinding in `outpost` to a Role that allows `create`, `get`, `list` and `watch` on `teamenvironments` in the group `platform.starfleet.io`. You run `kubectl auth can-i create teamenvironments.platform.starfleet.io -n starfleet --as outpost-dev --as-group outpost-team`. What is the answer, and why?

- A. `yes`, because the group has the Role.
- B. `no`, because a RoleBinding grants rights only in its own namespace.
- C. `yes`, because `create` on a custom resource works in every namespace.
- D. `no`, because `--as-group` cannot be combined with `--as`.

**Answer:** B

**Explanation:** The RoleBinding is in `outpost`, so the rights end at that namespace. A good check also covers a denied action, such as `create deployments.apps` or `get secrets`, and a second namespace. Without `--as-group`, the identity has no group and the check returns `no` even when the Role is right.

### Question 13

The platform team adds a new kind, `TeamEnvironment`. People who already hold the built-in `edit` ClusterRole must get access to it with no extra binding. Which action does this?

- A. Edit the built-in `edit` ClusterRole and add the new rules.
- B. Create a ClusterRole with the label `rbac.authorization.k8s.io/aggregate-to-edit: "true"` and rules for `teamenvironments`.
- C. Create a Role in every namespace and bind it to every user.
- D. Create a ClusterRole with `aggregationRule` for the label `aggregate-to-tenant`.

**Answer:** B

**Explanation:** The built-in `edit` ClusterRole is an aggregated role. A controller in the control plane copies the rules of every ClusterRole that carries its label into it. Direct changes to `edit` are overwritten. The label value must be the quoted string `"true"`. Use aggregation to extend built-in roles for the platform's own users. Do not bind tenants to `edit`, because it can read Secrets and create Deployments.

### Question 14

An Argo CD `AppProject` for the tenant lists one repository in `sourceRepos`, one destination namespace `outpost`, and this `namespaceResourceWhitelist`: group `platform.starfleet.io`, kind `TeamEnvironment`. No `clusterResourceWhitelist` is set. A request file in the repository contains a `ClusterRole`. What happens when Argo CD syncs the Application in this project?

- A. Argo CD applies the `ClusterRole`, because the repository is allowed.
- B. Argo CD applies the `ClusterRole` in the namespace `outpost`.
- C. Argo CD refuses the `ClusterRole`, because the project allows no cluster-scoped resource kind.
- D. Argo CD moves the `ClusterRole` to the project `default`.

**Answer:** C

**Explanation:** An AppProject limits the repositories, destinations and resource kinds of its Applications. With no `clusterResourceWhitelist`, the project may create no cluster-scoped resource such as a Namespace or a ClusterRole. This stops a request file from granting itself more rights. An Application in the project `default` has no such limit.

### Question 15

An Application has `syncPolicy.automated` with `prune: true` and `selfHeal: true`. A platform engineer fixes a drifted `TeamEnvironment` with `kubectl edit`, and later a tenant deletes its request file from Git. What happens?

- A. The `kubectl edit` change stays, and the object stays after the file is deleted.
- B. Argo CD reverts the `kubectl edit` change, and it deletes the object from the cluster after the file is deleted.
- C. Argo CD keeps the `kubectl edit` change, and it deletes the object after the file is deleted.
- D. Argo CD reverts the `kubectl edit` change, and it keeps the object after the file is deleted.

**Answer:** B

**Explanation:** With `selfHeal: true`, Argo CD reverts changes made directly in the cluster, so Git stays the single source of truth. With `prune: true`, it deletes a cluster object when its file leaves Git. Change the file in Git instead of editing the object.

### Question 16

A tenant commits a `TeamEnvironment` file. The Application shows `Synced`. The command `kubectl -n outpost get teamenvironment drifter` shows `SYNCED True` and `READY False` for several minutes. Where do you look next?

- A. The Application `status.conditions`, because Argo CD built the environment.
- B. The Git server log, because the file is probably wrong.
- C. The AppProject, because it blocked the object.
- D. The conditions of the composite resource, with `kubectl -n outpost describe teamenvironment drifter`. The `Message` names the composed object or function that failed.

**Answer:** D

**Explanation:** `Synced` on the Application means the file reached the cluster. The object exists, so Git and Argo CD did their jobs. Crossplane builds the environment and reports its own conditions on the composite resource, and only `Ready True` there means the environment works. If the object does not exist, read the Application first. A project violation, or a request that the API server refuses (for example `size: huge`), shows in the Application conditions and sync result message.
