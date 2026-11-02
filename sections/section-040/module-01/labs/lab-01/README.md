---
estimated_duration: 20m
---

# Submit A Parameterized Provisioning WorkflowTemplate

The platform team wants to onboard new teams with one stored Argo Workflows definition. In this lab you write a WorkflowTemplate with two parameters and a DAG of three tasks, then submit a Workflow from it with overridden values.

## Launching the Lab

Run this command to start the cluster:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-01/labs/lab-01
```

When you think you have finished, send it for grading:

```bash
astrona submit -c sections/section-040/module-01/labs/lab-01
```

When you are done, remove the lab:

```bash
astrona destroy ats-019-lab-040-01
```
