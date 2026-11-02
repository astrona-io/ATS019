---
estimated_duration: 30m
---

# Deliver A Tenant Request Through Argo CD

A graded troubleshooting lab. The cluster runs Crossplane with the
`TeamEnvironment` XRD and Composition, Gitea with the repository
`starfleet/outpost-requests`, and Argo CD. The Application
`outpost-requests` and the AppProject `outpost` start broken on purpose. The
learner reads the Application status, fixes the project and the Application,
commits `requests/drifter.yaml`, and follows the request to `Ready`. The grader
rejects the plausible wrong fixes: the `default` project, a wildcard kind, and
applying the request with `kubectl`.

## Run it

The cluster needs outbound internet and takes several minutes to start.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-040/module-03/labs/lab-02
astrona submit -c sections/section-040/module-03/labs/lab-02
astrona destroy ats-019-lab-040-03-02
```

Authors: `astrona run -c sections/section-040/module-03/labs/lab-02` runs the
local copy, and `astrona test -c sections/section-040/module-03/labs/lab-02`
proves the grading passes with `solution/apply.sh`.
