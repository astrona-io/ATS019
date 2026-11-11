---
estimated_duration: 30m
---

# Wait For A TeamEnvironment With A Resource Step

The WorkflowTemplate `request-environment` does not exist yet. In this lab you build it: a resource step that creates a `TeamEnvironment` in the namespace `outpost` and keeps waiting until the object reports `status.phase` as `Ready`. You also give the ServiceAccount `provisioner` the narrow permissions that waiting needs.

## Launching the Lab

Run this command to start the cluster:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-01/labs/lab-03
```

When you think you have finished, send it for grading:

```bash
astrona submit -c sections/section-040/module-01/labs/lab-03
```

When you are done, remove the lab:

```bash
astrona destroy ats-019-lab-040-01-03
```
