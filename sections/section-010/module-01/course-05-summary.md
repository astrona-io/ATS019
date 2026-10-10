# Summary

A CustomResourceDefinition adds a new resource type to the API server, and its schema is the only thing the API server checks a custom resource against. A schema that keeps unknown fields and types nothing lets typos and impossible values into etcd, where every later reader inherits them.

## What you learned

A create or update request for a custom resource passes decoding, pruning, defaulting, schema validation and CEL rules inside the API server, before any admission webhook and before etcd. A structural schema gives every field a `type`; `required`, `enum`, `minimum`, `maximum` and `pattern` limit what is accepted, and `default` fills in missing fields. `kubectl` asks for strict field validation, so the API server refuses unknown fields from it; clients that do not ask get the unknown fields pruned without a word.

The API server prunes and defaults on every read as well, but it validates only on writes. Objects stored under an older schema keep values the new schema forbids. Validation ratcheting lets an update keep an invalid value that does not change, and refuses an update that changes a field to another invalid value.

CEL rules in `x-kubernetes-validations` check what one field's limits cannot. A rule on `spec` can compare two fields through `self`. A transition rule uses `oldSelf`, runs only on updates, and is the usual way to make a field immutable. Guard optional fields with `has()`. When schema checks fail, the API server skips the CEL rules and says so, and `--dry-run=server` runs every check without storing anything.

`additionalPrinterColumns` decides what `kubectl get` shows, with `type: date` for ages and `priority` for `-o wide`; listing columns removes the default `Age` column. `shortNames` and `categories` make a type quick to find and list. The key facts to remember are these:

- A CRD's name is always `<plural>.<group>`, and its schema must be structural.
- Validation runs on writes; pruning and defaulting also run on reads.
- A rule you never saw refuse a request is a rule you cannot trust.
- Old invalid values stay until an update changes them.

<!-- astrona:playground:destroy -->
