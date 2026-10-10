# Welcome To The Course

This course trains you for the **Platform APIs and Self-Service Capabilities** part of the **Certified Cloud Native Platform Engineer (CNPE)** exam. That part is 25% of the exam. This page tells you who the course is for, what you can do at the end, which words and example workloads it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, Deployments, Services, labels, `kubectl apply`, `kubectl get -o yaml` and `kubectl describe`. You can read a YAML manifest and find a field in it. You do not need to know Crossplane, Argo Workflows or how an operator works. Each new idea is explained the first time it appears.

## What you can do at the end

The exam is hands-on. You get live clusters and a list of tasks, and you have to make things work under time pressure. The exam also covers many tools, and it expects you to use each one for a clear job rather than know every corner of it. So this course teaches, for each tool, the job the exam asks of it, the fields that do that job, and how to read the tool's status when something fails. The exam groups this part into four topics, and each one turns into a set of skills you will practise.

The first topic is **designing Custom Resource Definitions (CRDs) for platform services**. A platform team offers its services through the Kubernetes API, and a CRD is how a new resource type gets into that API. You will learn to:

- Write a CRD with an OpenAPI v3 schema that types, defaults and requires fields.
- Add Common Expression Language (CEL) validation rules that reject bad input at the API server.
- Add printer columns so `kubectl get` shows the fields that matter.
- Serve two versions of a CRD, choose the storage version, and turn on the `status` and `scale` subresources.

A new resource type does nothing on its own. A controller has to act on it, so the second topic is **using Kubernetes operators for platform automation**. You will learn to:

- Follow an operator's reconcile loop from a custom resource to the objects it creates.
- Read `status.conditions` and `observedGeneration` to tell whether an operator has acted on your change.
- Explain how finalizers and owner references decide what happens when you delete an object.

The third topic is **workflows for self-service provisioning using platform APIs**, built with Crossplane. You will learn to:

- Install a Crossplane provider and give it a ProviderConfig.
- Define a new platform API with a CompositeResourceDefinition (XRD) and a Composition built from functions.
- Request a composite resource and trace it down to every object it created.

The fourth topic is **automation frameworks for self-service provisioning**. You will learn to:

- Run a provisioning job as an Argo Workflows `WorkflowTemplate` with parameters.
- Start a workflow from an event.
- Let a tenant team request a service through Git and the platform API, with role-based access control (RBAC) that allows nothing else.

Everything is built and checked on **Kubernetes 1.35**, the version the exam uses, with **Crossplane 2.4.2** and **Argo Workflows 4.1.5**.

## The words this course uses

The pages use the Kubernetes, Crossplane and Argo terms, because those are the words you meet in the product, the logs and the exam. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

A **resource type** is a kind of object the Kubernetes API server knows, such as `Deployment` or `Service`. A **CustomResourceDefinition (CRD)** adds a new resource type, and each object of that type is a **custom resource**. A **controller** is a program that watches objects and changes the cluster until it matches what they ask for. It does this in a **reconcile loop**: read the desired state, read the actual state, act on the difference, and write the result into the object's `status`. An **operator** is a controller plus its CRDs, built to run one application or service for you.

Crossplane adds its own layer on top of these ideas:

| Crossplane object | What it does |
| --- | --- |
| CompositeResourceDefinition (XRD) | Defines a new platform API: the schema of a composite resource |
| Composite resource (XR) | One request made through that API, for example "a team environment" |
| Composition | Says which resources to create for a composite resource, as a pipeline of functions |
| Provider and ProviderConfig | A provider installs a controller for one system; its ProviderConfig says how to connect |
| Managed resource | One object a provider creates and keeps in the state you asked for |

## The example workloads in your playground

The playgrounds and labs use the same small set of workloads. `scout` is a small web API on port `9898`, and it is the workload a platform API usually provisions. `probe` is an HTTP echo server on port `8080`, used where a second workload is needed. You send test requests from `shuttle`, a client pod with `curl`.

Two namespaces come back often. `starfleet` belongs to the platform team, which builds the platform APIs. `outpost` belongs to a tenant team, which uses them. Where a module needs a Git server, Gitea runs inside the cluster in the `gitea` namespace, so everything works without an outside account. Some playgrounds and labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has four sections, in the order you build a platform API: the API object first, then the controller that acts on it, then the engine that turns one request into many objects, and last the self-service workflow around it.

| Section | What it covers |
| --- | --- |
| 010 | Extending The Kubernetes API With CRDs |
| 020 | Platform Automation With Operators |
| 030 | Platform APIs With Crossplane |
| 040 | Self-Service Provisioning Workflows |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a set starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, combining every module in it | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, the real output, and then what that output shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type or what you will see. Never change a command to make it "look right". If the result is different from the page, that difference is the lesson.
