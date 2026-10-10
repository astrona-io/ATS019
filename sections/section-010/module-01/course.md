# Design A CRD Schema That Validates Input

A platform API starts with a new resource type. A team writes one short object, such as "an environment for team `outpost`, size small, two replicas", and the platform does the rest. Before anything can act on that object, the API server must accept the good requests and refuse the bad ones. If it stores a misspelled field or a replica count of 50, every tool that reads the object later inherits the mistake.

A CustomResourceDefinition (CRD) is the Kubernetes object that adds a new resource type to the API server. Its schema decides what the API server checks, what it fills in and what it throws away. This module turns a CRD that accepts anything into one that types every field, fills in defaults, enforces rules across fields with CEL, and shows the important fields in `kubectl get`.

Keep one sentence in mind: **the API server enforces the schema on every write, and nothing else enforces it for you.** There is no controller in this module. Every check you see is done by the API server itself, from the CRD alone.

The module has four parts. **What A CRD Adds To The API Server** looks at a CRD with a weak schema, follows a request through the API server and shows what that schema lets in. **Types, Required Fields, Defaults And Pruning** gives every field a type and a limit, and shows what happens to new objects and to objects that were stored before the change. **Rules Across Fields With CEL** adds rules that compare two fields, and a rule that compares a new value with the old one. **Printer Columns, Short Names And Categories** makes `kubectl get` show the fields a platform team checks every day.

## Learning objectives

After this module you can:

- Write a CustomResourceDefinition in `apiextensions.k8s.io/v1` with a structural `openAPIV3Schema` for a platform service.
- Mark fields as required and constrain them with `enum`, `minimum`, `maximum` and `pattern`.
- Set default values and predict which unknown fields the API server prunes.
- Write a CEL rule in `x-kubernetes-validations`, including a transition rule that uses `oldSelf`.
- Add `additionalPrinterColumns` and a short name so `kubectl get` shows the important fields.
- Prove a rule works by applying a custom resource the API server must reject.

## Before you start

You need Kubernetes basics: namespaces, YAML manifests, and the commands `kubectl get`, `kubectl apply` and `kubectl patch`. You do not need to know any programming language. CEL rules are one-line expressions, and the parts explain every one.

You write every file on your own machine, in a new, empty folder. Run every command from that folder.

Your playground is a single-node `kind` cluster running Kubernetes 1.35, with no add-ons. It holds these objects:

| Object | What it is |
| --- | --- |
| CRD `teamenvironments.platform.starfleet.io` | Adds the kind `TeamEnvironment` in version `v1alpha1`. Its schema accepts any `spec` on purpose |
| `TeamEnvironment` `alpha` in `outpost` | A correct object: team, size `small`, 2 replicas, a contact address |
| `TeamEnvironment` `beta` in `outpost` | The field `replicas` is misspelled as `replcas` |
| `TeamEnvironment` `gamma` in `outpost` | Size `huge` and 50 replicas, and the contact is `nobody` |

The namespaces `starfleet` and `outpost` exist. No controller acts on the CRD, so the objects never get a `status`; that is on purpose. Every command in the parts runs against the playground cluster, and `kubectl` already points at it.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
