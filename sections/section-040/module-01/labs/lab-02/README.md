---
estimated_duration: 25m
---

# Fix A Provisioning Workflow That Fails On Permissions

The WorkflowTemplate `deploy-scout` should create the `scout` Deployment and Service in the namespace `outpost`, but every run ends as `Failed`. In this lab you read the failure, find the missing permissions and fix them with a narrow Role.

## Launching the Lab

Run this command to start the cluster:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-01/labs/lab-02
```

When you think you have finished, send it for grading:

```bash
astrona submit -c sections/section-040/module-01/labs/lab-02
```

When you are done, remove the lab:

```bash
astrona destroy ats-019-lab-040-02
```
