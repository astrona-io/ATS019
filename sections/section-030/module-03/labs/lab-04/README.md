---
estimated_duration: 15m
---

# Trace And Repair A Composed Resource

- **Slug:** ats-019-lab-030-03-04
- **Author:** Paris Nakita Kejser
- **Type:** Astrona hands-on lab, graded

The learner traces a namespaced `TeamEnvironment`, records the failing
composed resource and its condition, and repairs a provider configuration
reference in the Composition. The shared Crossplane bootstrap comes from
the module's other labs. The CLI download is required rather than optional.

Bootstrap stores SHA-256 digests of the actual failing condition and the
object identities in `starfleet/trace-baseline`, so the learner cannot read
the answer from it. The diagnosis check compares the report with
that snapshot and the child's live identity, owner and resource reference.
This keeps the diagnosis gradeable after reconciliation replaces the error
condition. The readiness check reads the live request, children and Service.
Both checks fail on the untouched starting state.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-03/labs/lab-04
astrona submit --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-030/module-03/labs/lab-04
astrona destroy ats-019-lab-030-03-04
```

Authors can validate the configuration without starting the environment:

```sh
astrona validate -c sections/section-030/module-03/labs/lab-04
```

Built without booting on 2026-11-06. Runtime behaviour is untested.
