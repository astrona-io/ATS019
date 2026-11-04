---
estimated_duration: 20m
---

# Solution

You store one WorkflowTemplate with two parameters and a DAG, then submit a Workflow that overrides both parameters. Everything happens in the namespace `starfleet` with `kubectl`.

| Goal | Where it lives | Field |
| --- | --- | --- |
| Input values with defaults | the WorkflowTemplate | `spec.arguments.parameters` |
| Read a value in a template | any template | `{{workflow.parameters.<name>}}` |
| Run two tasks at once, then a third | the `dag` template | `dependencies` |
| Start a stored template | the Workflow | `spec.workflowTemplateRef` |

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch -c sections/section-040/module-01/labs/lab-01
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

## Step 1: Look at the starting state

Argo Workflows runs in the namespace `argo`, and no template exists yet:

```bash
kubectl -n argo get deployment workflow-controller
kubectl -n starfleet get workflowtemplates
```

The controller Deployment is ready. The second command reports that no WorkflowTemplate exists. Nothing is graded yet.

## Step 2: Store the WorkflowTemplate

Save this as `workflowtemplate-onboard-team.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: WorkflowTemplate
metadata:
  name: onboard-team
  namespace: starfleet
spec:
  entrypoint: graph
  arguments:
    parameters:
      - name: team
        value: outpost
      - name: size
        value: small
  templates:
    - name: graph
      dag:
        tasks:
          - name: check-team
            template: say
            arguments:
              parameters:
                - name: message
                  value: "team {{workflow.parameters.team}} is known"
          - name: check-size
            template: say
            arguments:
              parameters:
                - name: message
                  value: "size {{workflow.parameters.size}} is allowed"
          - name: announce
            dependencies: [check-team, check-size]
            template: say
            arguments:
              parameters:
                - name: message
                  value: "onboarding {{workflow.parameters.team}} with size {{workflow.parameters.size}}"
    - name: say
      inputs:
        parameters:
          - name: message
      container:
        image: curlimages/curl
        command: ["sh", "-c"]
        args: ["echo \"{{inputs.parameters.message}}\""]
```

What the fields do:

* `entrypoint: graph` names the template that runs first.
* `spec.arguments.parameters` declares `team` and `size` with their default values. Parameter values are strings.
* `dag.tasks` lists the tasks. `check-team` and `check-size` have no `dependencies`, so the controller starts both at once.
* `dependencies: [check-team, check-size]` makes `announce` wait for both.
* The template `say` takes one input parameter `message` and prints it. The message of `announce` is the line the grader looks for.

Apply it:

```bash
kubectl apply -f workflowtemplate-onboard-team.yaml
```

The watch terminal shows the check `verify-template` passing now. The checks `verify-parameters` and `verify-submitted-workflow` pass later.

## Step 3: Try the template with its defaults

Save this as `workflow-defaults.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: onboard-test-
  namespace: starfleet
spec:
  workflowTemplateRef:
    name: onboard-team
```

Create it with `kubectl create`, because `generateName` does not work with `kubectl apply`:

```bash
kubectl create -f workflow-defaults.yaml
kubectl -n starfleet get workflows
```

The Workflow runs and ends as `Succeeded`. Read the output of its steps. Replace `<name>` with the name that `kubectl get workflows` shows:

```bash
kubectl -n starfleet logs -l workflows.argoproj.io/workflow=<name> -c main
```

One of the three lines is `onboarding outpost with size small`. The check `verify-parameters` passes now.

## Step 4: Submit the Workflow for drifter

Save this as `workflow-onboard-drifter.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: onboard-drifter
  namespace: starfleet
spec:
  workflowTemplateRef:
    name: onboard-team
  arguments:
    parameters:
      - name: team
        value: drifter
      - name: size
        value: large
```

The values in `spec.arguments.parameters` of the Workflow win over the defaults of the template. Create the Workflow and read its output:

```bash
kubectl create -f workflow-onboard-drifter.yaml
kubectl -n starfleet get workflow onboard-drifter
kubectl -n starfleet logs -l workflows.argoproj.io/workflow=onboard-drifter -c main
```

The Workflow ends as `Succeeded`, and one line is `onboarding drifter with size large`. The check `verify-submitted-workflow` passes now.

## Step 5: Submit

Press Ctrl-C to stop the watch, then run the submit command once:

```bash
astrona submit -c sections/section-040/module-01/labs/lab-01
```

All three checks pass.

## If a check stays red

* **`verify-template` says the entrypoint is not a dag template.** You used a `steps` template. Use `dag`.
* **`verify-template` says a check depends on something.** Two tasks that must run at the same time cannot depend on each other. Only `announce` has `dependencies`.
* **`verify-parameters` says no step printed the expected line.** The template still contains a fixed value, or the message does not read `{{workflow.parameters.team}}` and `{{workflow.parameters.size}}`. The grader runs the template with the values `graders` and `medium`.
* **`verify-parameters` says the Workflow did not succeed.** Read the failed node with `kubectl -n starfleet get workflow <name> -o yaml` and the log of the pod. A message with an unquoted parenthesis breaks `sh -c`, so keep the `echo "..."` quotes.
* **`verify-submitted-workflow` says the Workflow does not exist.** The name must be exactly `onboard-drifter`. A `generateName` Workflow gets a random name.
* **`kubectl create` says `AlreadyExists`.** The Workflow `onboard-drifter` exists. Delete it with `kubectl -n starfleet delete workflow onboard-drifter` and create it again.
