# Run Provisioning Steps With Argo Workflows

A platform API object, such as a `TeamEnvironment`, says what a team wants. Someone still has to run the steps that deliver it: check the request, create objects, wait until they are ready and test the result. Argo Workflows runs those steps inside the cluster, one pod per step, from a definition you store as a Kubernetes object.

A Workflow is an object that describes a run of steps. A WorkflowTemplate is a stored Workflow definition that you start many times with different input values. The workflow controller is the program that watches Workflow objects and creates a pod for each step. This module teaches the one job the exam asks of Argo Workflows: define a reusable provisioning workflow, give it only the permissions it needs, and read its status when it fails.

The module has four parts. **What Argo Workflows Runs** submits a first Workflow and follows it from the object to the pods. **Build A Reusable WorkflowTemplate** adds input parameters, ordered steps and a DAG of dependent tasks. **Give The Workflow A ServiceAccount** lets a step create a `scout` Deployment and Service in `outpost` and reads a failure caused by missing permissions. **Create A Platform API Object And Wait For Ready** uses a resource step to create a `TeamEnvironment` and wait for a success condition.

## Learning objectives

After this module you can:

- Write a WorkflowTemplate with input parameters, steps and a DAG of dependent tasks.
- Submit a Workflow from a WorkflowTemplate and override a parameter.
- Give a workflow a ServiceAccount with only the RBAC its steps need, and diagnose a step that fails on permissions.
- Read a workflow's phase, node status and step logs to find the failing step.
- Use a resource template step to create a custom resource and wait for a success condition.

## Before you start

You need Kubernetes basics: namespaces, Deployments, Services, pods, ServiceAccounts, Role-based access control (RBAC) and the commands `kubectl get`, `kubectl apply`, `kubectl logs` and `kubectl describe`. A CustomResourceDefinition (CRD) adds a resource type to the Kubernetes application programming interface (API). You do not need to know Argo Workflows.

Write each example file in a new, empty folder on your machine. Run every command from that folder. Your playground runs Kubernetes 1.35 in a single-node `kind` cluster. The exam allows `kubectl`, so this module uses `kubectl` first and shows the `argo` command-line tool only where it saves time.

| Namespace | What is in it |
| --- | --- |
| `argo` | Argo Workflows 4.1.5: the workflow controller and the Argo server |
| `starfleet` | The ServiceAccount `provisioner`, which has too few permissions on purpose |
| `outpost` | The tenant namespace where workflows create objects |

The `TeamEnvironment` CRD is installed, but no controller acts on its objects. You set their status by hand to simulate a controller. Crossplane is not installed.

Launch your playground now, and keep it running while you read:

<!-- astrona:playground -->
