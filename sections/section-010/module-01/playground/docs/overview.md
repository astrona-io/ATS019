# Overview: Design A CRD Schema That Validates Input (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with a CustomResourceDefinition whose schema checks almost nothing, plus three objects that schema accepted, and then waits. There is no task, no `astrona submit` and no pass or fail. Change the CRD, send good and bad objects, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35, with no add-ons. `kubectl` is already pointed at it.
- The CustomResourceDefinition `teamenvironments.platform.starfleet.io`. It adds the kind `TeamEnvironment` in version `v1alpha1`. Its schema says only that `spec` is an object, and keeps any field inside it (`x-kubernetes-preserve-unknown-fields: true`).
- Three `TeamEnvironment` objects in the namespace `outpost`:

  | Object | What is in its `spec` |
  | --- | --- |
  | `alpha` | team `outpost`, size `small`, 2 replicas, a valid contact address |
  | `beta` | the field `replicas` is misspelled as `replcas` |
  | `gamma` | size `huge`, 50 replicas, contact `nobody` |

- The namespaces `starfleet` and `outpost`. No controller acts on the CRD, so no object ever gets a `status`.

## Helpers

Paste these once in each new terminal. `show_spec` prints the `spec` of one `TeamEnvironment` in `outpost` on one line. `try_apply` sends a file through every check of the API server with a server-side dry run, and stores nothing.

```sh
show_spec() {
  kubectl -n outpost get teamenvironment "$1" -o jsonpath='{.spec}{"\n"}'
}
try_apply() {
  kubectl apply --dry-run=server -f "$1"
}
```

Use them like this: `show_spec beta`, `try_apply teamenvironment-test.yaml`.

## Practice tasks

- Read `beta` and `gamma` before you change the CRD. Write down what a controller would do with each one.
- Give the schema types and limits, then run `show_spec beta` again. Predict which field disappears and which ones appear before you look.
- Add a `description` to two fields and compare `kubectl explain teamenvironment.spec` before and after.
- Write a CEL rule that allows `retentionDays` above 30 only for size `large`. Prove it with one object that must be refused and one that must be accepted.
- Make `contact` immutable with a transition rule, then check whether you can still create a new object with any contact address.
- Add a printer column with `priority: 1` and compare `kubectl get teamenv` with `kubectl get teamenv -o wide`.
