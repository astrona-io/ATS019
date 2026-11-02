# Question

Solve this question on: `terminal`

The platform team publishes the API `TeamEnvironment` (group `platform.starfleet.io`, version `v1alpha1`, namespaced). Teams such as `outpost` create one object to ask for an environment. The CRD `teamenvironments.platform.starfleet.io` exists, but its schema keeps any field in `spec` and checks nothing. Objects with a misspelled field or with impossible values are stored, and the controller that will read them later has no way to tell.

Replace the schema of the CRD so the API server enforces the rules below. Change the existing CRD. Keep its name, kind, scope and the version `v1alpha1`, and do not delete the `TeamEnvironment` `alpha` in `outpost`.

When you finish, these must be true:

- The object has a `spec`. Inside `spec`, `team`, `size` and `contact` are required.
- `team` is a string of 1 to 30 characters.
- `size` is a string and must be one of `small`, `medium` or `large`.
- `replicas` is an integer from 1 to 5. When it is missing, the API server sets it to `1`.
- `retentionDays` is an integer from 1 to 90. When it is missing, the API server sets it to `7`.
- `contact` is a string that matches the pattern `^[a-z0-9.-]+@[a-z0-9.-]+$`.
- A field that the schema does not declare, such as the misspelled `replcas`, is refused by `kubectl` and pruned for a client that does not use strict validation. It is never stored.
- The schema must not use `x-kubernetes-preserve-unknown-fields` anywhere.
