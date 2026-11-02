# Overview: Run Provisioning Steps With Argo Workflows (Playground)

This playground gives you a cluster where you can submit workflows, read their status and break their permissions. A Workflow is a Kubernetes object that describes a run of steps. The workflow controller turns each step into a pod. There is nothing to submit and no grading.

## What's in the box

The single-node `kind` cluster runs Kubernetes 1.35.8 and Argo Workflows 4.1.5. A CustomResourceDefinition (CRD) adds a resource type to the Kubernetes application programming interface (API). Argo Workflows adds `Workflow`, `WorkflowTemplate` and `WorkflowTaskResult` this way.

| Namespace | Objects |
| --- | --- |
| `argo` | The workflow controller and the Argo server |
| `starfleet` | The ServiceAccount `provisioner`; the Role and RoleBinding `workflow-executor` |
| `outpost` | An empty tenant namespace where workflows create objects |

In Argo Workflows 4.x every step pod writes its result into a `WorkflowTaskResult` object. The Role `workflow-executor` gives the `default` ServiceAccount and the `provisioner` ServiceAccount the verbs `create` and `patch` on `workflowtaskresults` in `starfleet`. That is all they can do. `provisioner` has no permission at all in `outpost`.

The `TeamEnvironment` CRD (`platform.starfleet.io/v1alpha1`) is installed with the status subresource, but no controller acts on its objects. A subresource is an extra endpoint of a resource. The field `spec.team` is required. The field `spec.size` accepts `small`, `medium` or `large` and defaults to `small`. The field `spec.replicas` accepts `1` to `3` and defaults to `1`. The field `spec.contact` is optional. You write `status.phase` yourself to play the controller.

The images `curlimages/curl` and `ghcr.io/stefanprodan/podinfo:6.15.0` are loaded into the cluster before you start.

The `argo` command-line tool is downloaded to `~/.astrona/bin/argo` when the playground starts. If your shell cannot find `argo`, add the folder to your path with `export PATH="$HOME/.astrona/bin:$PATH"`. If the download failed, use `kubectl`. Everything the tool shows also lives in the Workflow objects.

## Practice tasks

- Submit the same Workflow three times with `kubectl create`. Read the phase of each run, then list the pods of one run and read the logs of its `main` and `wait` containers.
- Store a WorkflowTemplate with two parameters. Submit a Workflow that overrides one of them, then check which value each step printed.
- Write a DAG with two independent tasks and one task that depends on both. Check the start and finish times of the nodes in `status.nodes`.
- Make a step create a Deployment in `outpost` and read the `forbidden` message in the log. Before you fix it, ask `kubectl auth can-i --as=system:serviceaccount:starfleet:provisioner` for the exact verbs.
- Give `provisioner` the smallest Role that lets the step succeed. Then check that it still cannot delete the Deployment.
- Write a resource step that creates a `TeamEnvironment` and waits for `status.phase == Ready`. Patch the status subresource to finish the step. Repeat with `Failed`.
