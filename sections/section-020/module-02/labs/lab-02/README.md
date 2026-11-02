---
estimated_duration: 20m
---

# Restore A Cleanup Worker That Cannot Finish

Graded troubleshooting lab for the deletion module. The ConfigMap `probe-settings` in `starfleet` has the finalizer `platform.starfleet.io/cleanup` and a deletion timestamp. The Job `probe-cleanup` is the worker: it must delete `probe-cache` and then release the finalizer. The Job is suspended, and its Role does not allow `delete` on `probe-cache`. The learner restores the worker without removing the finalizer by hand and without widening access. A grader that checks the Job's `Complete` condition rejects the plausible wrong fix of patching the finalizer away.

The cluster needs no add-ons and no internet access. The image `registry.k8s.io/kubectl:v1.35.8` is preloaded.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-020/module-02/labs/lab-02
astrona submit -c sections/section-020/module-02/labs/lab-02
astrona destroy ats-019-lab-020-02-02
```

Authors can run the reference solution with `astrona test -c sections/section-020/module-02/labs/lab-02`.
