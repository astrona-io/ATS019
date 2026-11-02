---
estimated_duration: 20m
---

# Question

Solve this question on: `terminal`

The platform team onboards each new team with an Argo Workflows run. The first team to onboard is `drifter`. Argo Workflows 4.1.5 is running, and the namespace `starfleet` exists. Nothing else is prepared.

1.  **Store the template.** Create a WorkflowTemplate named `onboard-team` in the namespace `starfleet`.
2.  **Add two parameters.** The template has the input parameters `team` with the default value `outpost` and `size` with the default value `small`.
3.  **Build a DAG.** The entrypoint template is a `dag` template with exactly these three tasks:
    * `check-team` has no dependencies.
    * `check-size` has no dependencies, so it can run at the same time as `check-team`.
    * `announce` starts only after both `check-team` and `check-size` are done.
4.  **Print the result.** Every task runs a container with the image `curlimages/curl` that prints one line. The `announce` task prints exactly `onboarding <team> with size <size>`, where `<team>` and `<size>` are the values of the parameters. For the defaults the line is `onboarding outpost with size small`. The two check tasks print any one line you like.
5.  **Submit a Workflow.** Create a Workflow named `onboard-drifter` in `starfleet` from the template with `workflowTemplateRef`. Override the parameters: `team` is `drifter` and `size` is `large`. The Workflow ends as `Succeeded`.

Constraints:

* Do not write the values `drifter` or `large` into the template. They come from the Workflow.
* Run the steps with the `default` ServiceAccount of `starfleet`. Do not change any RBAC object.
