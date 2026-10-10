# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.

## About this repo (ATS019 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** pass the **Platform APIs and Self-Service Capabilities**
  domain of the **Certified Cloud Native Platform Engineer (CNPE)** exam. It
  is 25% of the exam.
- **What the exam really tests:** building and using platform APIs by hand,
  on a live cluster, under time pressure. The student must *do* things:
  write a CustomResourceDefinition that rejects bad input, read an
  operator's status conditions, define a Crossplane
  CompositeResourceDefinition and Composition, trace a composite resource to
  the objects it created, and run a provisioning workflow. The exam covers
  many tools at shallow depth and gives only a short per-task quick
  reference, so every page must teach the one job the exam asks of a tool,
  the fields that do that job, and how to read the tool's status when it
  fails.
- **The four exam competencies (curriculum items):**
  - Designing and Creating Custom Resource Definitions (CRDs) for Platform Services
  - Using Kubernetes Operators for Platform Automation and Integration
  - Implementing Workflows for Self-Service Provisioning Using Platform APIs
  - Using Automation Frameworks for Self-Service Provisioning
- **The sections:** the order is the order of building a platform API from
  the bottom up: the API object itself, the controller that acts on it, the
  composition engine that turns one request into many objects, and the
  self-service workflow around it. The README table maps each section to its
  curriculum item.

  | Section | Title | Curriculum item |
  | --- | --- | --- |
  | 010 | Extending The Kubernetes API With CRDs | Designing and Creating Custom Resource Definitions (CRDs) for Platform Services |
  | 020 | Platform Automation With Operators | Using Kubernetes Operators for Platform Automation and Integration |
  | 030 | Platform APIs With Crossplane | Implementing Workflows for Self-Service Provisioning Using Platform APIs |
  | 040 | Self-Service Provisioning Workflows | Using Automation Frameworks for Self-Service Provisioning / Implementing Workflows for Self-Service Provisioning Using Platform APIs |

- **The version:** everything is built and checked on **Kubernetes 1.35**
  (the version the exam runs) in a single-node `kind` v0.33.0 cluster
  (`kindest/node:v1.35.8`). Pinned tools:

  | Tool | Version |
  | --- | --- |
  | Crossplane | 2.4.2 |
  | `provider-kubernetes` | 1.4.1 |
  | `function-patch-and-transform` | 0.11.0 |
  | Prometheus Operator | 0.94.1 |
  | Prometheus | 3.15.0 |
  | Argo Workflows | 4.1.5 |
  | Argo Events | 1.9.11 |
  | Argo CD | 3.5.4 |
  | Gitea | 28.1.0 (plumbing only) |
  | Helm | 4.3.0 (plumbing only) |

  Do not teach fields, flags or output from other versions without saying so.
  Crossplane 2.x and Argo Workflows 4.x changed a lot from the versions most
  blog posts describe.
- **Teach only tools from the official CNPE list.** The list is Argo (CD,
  Workflows, Events), Crossplane, Flagger, Flux, Gatekeeper, Grafana, Istio,
  Jaeger, Kyverno, Linkerd, OPA, OpenCost, OpenTelemetry, Prometheus and
  Tekton, plus built-in Kubernetes (CRDs, CEL, RBAC, `kubectl`). Any other
  tool (Gitea, Helm, cert-manager) is plumbing: the bootstrap installs and
  seeds it, and a page names it in one sentence at most. Never make it a
  lesson subject, and never ask the reader to run its CLI.
- **The main sources:** the Kubernetes pages on extending the API
  (<https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/>),
  the Crossplane documentation (<https://docs.crossplane.io/v2.4/>) and the
  Argo Workflows documentation (<https://argo-workflows.readthedocs.io/>).
  Check every page against them. The exam itself allows only
  `kubernetes.io/docs`, the Kubernetes blog and a per-task quick reference, so
  pages should show where on `kubernetes.io` a CRD field is documented.

### Terms, not metaphors

Explanations use Kubernetes', Crossplane's and Argo's own words. Define each
one in plain technical language on first use in a file, for example:

| Term | First-use definition (example wording) |
| --- | --- |
| CustomResourceDefinition (CRD) | A Kubernetes object that adds a new resource type (a new `kind`) to the API server |
| Custom resource | One object of a type that a CRD added, stored in etcd like any built-in object |
| OpenAPI v3 schema | The `openAPIV3Schema` in a CRD version; the API server uses it to validate, default and prune fields |
| Structural schema | A schema where every field has a type; required for CRDs in `apiextensions.k8s.io/v1` |
| Pruning | The API server drops fields the schema does not declare, unless `x-kubernetes-preserve-unknown-fields` is set |
| CEL validation rule | A rule in `x-kubernetes-validations` written in the Common Expression Language (CEL); the API server rejects an object when the rule is false |
| Printer columns | `additionalPrinterColumns`: the extra columns `kubectl get` shows for a custom resource |
| Subresource | An extra endpoint of a resource; `status` lets a controller write status separately from `spec`, `scale` lets `kubectl scale` and the HPA change replicas |
| Storage version | The one version of a CRD that the API server writes to etcd; `served` versions are the ones clients may use |
| Controller | A program that watches objects and changes the cluster until it matches what the objects ask for |
| Reconcile loop | The cycle a controller repeats: read desired state, read actual state, act on the difference, write status |
| Operator | A controller plus its CRDs that runs one application or service on behalf of the user |
| Condition | An entry in `status.conditions` with a `type`, a `status` (`True`, `False`, `Unknown`), a `reason` and a `message` |
| `observedGeneration` | The `metadata.generation` a controller last acted on; when it is lower than `generation`, the status is old |
| Finalizer | A name in `metadata.finalizers`; the API server keeps the object until the controller removes it, so cleanup can run first |
| `ownerReference` | A link in `metadata.ownerReferences` from a child object to its parent; the garbage collector deletes the child when the parent goes |
| CompositeResourceDefinition (XRD) | A Crossplane object that defines a new platform API: the schema of a composite resource |
| Composite resource (XR) | One object of the type an XRD defines; in Crossplane 2.x it is namespaced by default |
| Composition | A Crossplane object that says which resources to create for a composite resource, as a pipeline of functions |
| Composition function | A program in the Composition pipeline that returns the resources to create (for example `function-patch-and-transform`) |
| Provider | A Crossplane package that installs CRDs and a controller for one external system (for example `provider-kubernetes`) |
| ProviderConfig | The object that tells a provider how to connect and which credentials to use |
| Managed resource | One object a provider controls, for example a provider-kubernetes `Object` |
| Workflow | An Argo Workflows object that runs a series of steps, each step in its own pod |
| WorkflowTemplate | A stored, reusable Workflow definition with input parameters |
| EventSource / Sensor | Argo Events objects: the EventSource receives events (for example a webhook); the Sensor starts an action, such as a Workflow, when an event matches |

### The example workloads

Every section uses the same small set of workloads. A module creates them in
its own namespace when it needs a workload to provision or manage. The
Kubernetes names are plain names, so describe them in technical terms and use
them as they are.

| Kubernetes name | Image | What it is |
| --- | --- | --- |
| `scout` (Deployment and Service) | `ghcr.io/stefanprodan/podinfo:6.15.0` | Small web API on port `9898`; the default workload a platform API provisions |
| `probe` (Deployment and Service) | `mccutchen/go-httpbin:v2.25.0` | HTTP echo server on port `8080`, used where a second workload is needed |
| `shuttle` | `curlimages/curl` | Client pod; requests are sent from here with `kubectl exec deploy/shuttle -- curl ...` |

Namespaces: `starfleet` is the platform team's namespace and `outpost` is a
tenant team's namespace. A self-service request comes from `outpost` and the
platform API provisions into it or into a namespace it creates. The in-cluster
Git server is Gitea in namespace `gitea`, reachable at
`http://gitea-http.gitea.svc:3000`, with the user `platform` and the
organisation `starfleet`.

### Environment facts the text must respect

- **Pin the cluster in `config.yaml`.** astrona's kind runtime takes
  `runtime.kind.image: kindest/node:v1.35.8` (or `runtime.kind.version`),
  `runtime.kind.nodes.workers`, `featureGates`, `runtimeConfig`,
  `preloadImages` and addons (`metricsServer`, `certManager`,
  `gatewayAPI: envoy`, `cni: calico`); see `astrona schema`. Prefer an addon
  over a hand-written install when it fits. It does not expose
  `kubeadmConfigPatches` or `extraMounts`.

- **Everything runs offline in `kind`.** Crossplane never reaches a cloud
  provider. Compositions create objects inside the same cluster through
  `provider-kubernetes` (an `Object` that wraps any Kubernetes manifest). Say so on the
  first Crossplane page, and teach the pattern so it transfers to cloud
  providers.
- **Crossplane 2.x facts (verify each before the first page that uses it):**
  - XRDs use `apiextensions.crossplane.io/v2`; composite resources are
    namespaced by default (`scope: Namespaced`). Claims exist only for
    `scope: LegacyCluster`. Do not teach claims as the default.
  - Compositions use `mode: Pipeline` with functions. The old `resources:`
    patch-and-transform mode is gone.
  - The CLI traces a resource with `crossplane resource trace <kind> <name>`
    and renders a Composition locally with
    `crossplane composition render xr.yaml composition.yaml functions.yaml`.
    `crossplane beta trace` is the older name.
- **Operators are used, not written.** The course never builds an operator
  in Go. The reconcile loop is shown with an operator from the CNPE list,
  the Prometheus Operator (a `Prometheus` resource and the StatefulSet,
  Service and Secrets it creates and owns), installed from its plain
  `bundle.yaml`, and with Crossplane itself.
- **Install only what the module needs.** The maintainer's Podman machine
  has 10 GiB of memory. A CRD playground needs no add-ons at all; a Crossplane
  playground installs Crossplane and one or two providers; only the
  self-service section installs Gitea, Argo Workflows or Argo CD, and never
  all of them together unless the module needs it.
- **Providers and functions are packages pulled from `xpkg.crossplane.io`,**
  so the Crossplane environments need outbound internet and take longer to
  start. A provider is ready when `kubectl get providers` shows
  `INSTALLED True` and `HEALTHY True`.
- **Some environments start broken on purpose.** A CRD whose schema accepts
  bad input, a Composition that references a missing function, a
  ProviderConfig with no permissions: the fault is the material. Never "fix"
  it in the bootstrap.
- **The proof is the object's status.** A fix is proven with the custom
  resource or composite resource reporting `Ready` / `Synced` `True`, with
  the objects it should own present, and, where a workload is provisioned,
  with a request from `shuttle` that gets a `200`.

### Where things are in this repo

| What | Where |
| --- | --- |
| Course design record (sections, modules, objectives, playground environments) | `.astrona/blueprint.yaml` |
| Course outline the platform reads: every reading page and lab, in order. Never list `solution.md` here | `astrona.yaml` |
| Overview, sections and modules tables, how to run things | `README.md` |
| Introduction (see "Every course starts with an Introduction") | `sections/intro/` |
| Section overview and its modules | `sections/section-0N0/README.md` |
| Module reading: landing page, deep-dive parts, closing page | `sections/section-0N0/module-0M/course.md`, `course-0N-*.md` |
| Graded lab: task, walkthrough, setup, grader | `.../labs/lab-01/` (`question.md`, `solution.md`, `prerequisites.md`, `bootstrap/`, `manifests/`, `solution/`, `testing/`, `validation/`) |
| Ungraded sandbox for a module | `.../playground/` (`config.yaml`, `bootstrap/prepare.sh`, `manifests/`, `docs/overview.md`, which is the only learner page) |
| One graded integration lab per section | `sections/section-0N0/capstone/labs/lab-01/` |

A lab folder holds:

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition; `metadata.docs` points at `question.md` and `solution.md` |
| `README.md` | Short intro for authors with `estimated_duration` front matter and the run, submit and destroy commands |
| `prerequisites.md` | What the learner needs before starting |
| `question.md` | The exam-style task. Starts with `# Question` and `Solve this question on: \`terminal\`` |
| `solution.md` | Step-by-step walkthrough with real output |
| `bootstrap/` | Tool installs (`01-install-crossplane.sh` and similar) and the starting state |
| `manifests/` | Starting objects, including any faulty configuration the learner must fix |
| `solution/apply.sh`, `solution/solution.yaml` | Reference end state, applied only by `astrona test` |
| `testing/` | Helpers `astrona test` runs (for example a wait for a provider to be healthy) |
| `validation/validate-*.sh` | Behavioural grading, one script per check |

### Lab metadata in `astrona.yaml`

`astrona.yaml` has a `training:` block (id `ATS019`, domain `Platform APIs
and Self-Service Capabilities`, weight `25`) and one entry per section under
`modules:` (`module-intro`, `module-010`, `module-020` and so on). Each
section's `content` lists, in order: the section `README.md`, then for each
module its landing page, its parts, and right after the part a lab tests, a
`Question` reading (`labs/lab-01/question.md`) followed by the `type: lab`
entry; the module's closing page comes last. The section capstone closes the
section. Playgrounds are not listed: the landing page's
`<!-- astrona:playground -->` marker shows them.

Every `type: lab` entry (module labs and capstones) carries these fields, in
this order:

```yaml
      - type: reading
        title: Question
        path: sections/section-010/module-01/labs/lab-01/question.md
      - type: lab
        title: "Validate A Platform API With A CRD Schema Lab"
        path: sections/section-010/module-01/labs/lab-01
        difficulty: beginner
        estimated_duration: 20m
        topic: crd
        task_kind: build
        tags: [crd, openapi-schema, cel-validation, printer-columns]
        learning_goals:
          - Write a CRD schema that rejects a missing or out-of-range field
          - Prove the API server refuses an invalid custom resource
        resources:
          - name: "Extend the Kubernetes API with CustomResourceDefinitions"
            url: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/
```

- `difficulty`: `beginner`, `intermediate` or `advanced`.
- `estimated_duration`: realistic time to solve it, for example `15m`, `30m`, `45m`.
- `topic`: exactly one of `crd`, `operators`, `crossplane`, `workflows`,
  `self-service`, `rbac`.
- `task_kind`: exactly one of `build` (write the configuration from
  scratch), `troubleshooting` (find and fix what is broken) or `migration`
  (move a working setup to another version or layout, for example a new CRD
  version). The platform filters labs by it, so it is a field of its own,
  never a tag.
- `tags`: 4 to 8 ids, only from the tag list below. Add a new tag to the list
  first if nothing fits.
- `learning_goals`: 2 or 3 plain sentences, each starting with a verb, saying
  what the learner proves in this lab.
- `resources`: 1 to 4 documentation pages, each with a `name` and a `url`
  that loads. This is the **only** place outside links are allowed: the
  platform shows them as optional further reading next to the lab.

**Tag list** (lower case, hyphens, never synonyms):

- CRDs: `crd`, `openapi-schema`, `structural-schema`, `defaulting`,
  `pruning`, `cel-validation`, `printer-columns`, `crd-versions`,
  `storage-version`, `status-subresource`, `scale-subresource`
- Operators: `operator`, `reconcile-loop`, `conditions`,
  `observed-generation`, `finalizers`, `owner-references`,
  `prometheus-operator`, `garbage-collection`
- Crossplane: `crossplane`, `provider`, `provider-config`,
  `provider-kubernetes`, `xrd`, `composite-resource`,
  `composition`, `composition-functions`, `patch-and-transform`,
  `managed-resource`, `resource-trace`
- Automation: `argo-workflows`, `workflow-template`, `workflow-parameters`,
  `argo-events`, `sensor`, `argo-cd`, `gitops-request`
- Access: `rbac`, `service-account`, `aggregated-clusterrole`

### Running things

```bash
# Playground (ungraded)
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-010/module-01/playground
astrona destroy ats-019-playground-010-01   # takes metadata.name from config.yaml, not the path

# Lab or capstone (graded against the live cluster)
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-019-lab-010-01

# Authors: run a local, uncommitted copy, and prove a lab passes with its reference solution
astrona run -c sections/section-010/module-01/playground
astrona test -c sections/section-010/module-01/labs/lab-01
```

Names: a playground is `ats-019-playground-<section>-<module>`, a module lab
is `ats-019-lab-<section>-<module>` and a capstone is
`ats-019-capstone-<section>`; keep those names. A second lab in a module
takes `ats-019-lab-<section>-<module>-<lab>`, for example
`ats-019-lab-030-02-02`, so two labs never share a name. Lab bootstrap
scripts do not pin a kube context: astrona sets `KUBECONFIG` for the lab, and
`astrona test` runs on a cluster with a different name. Every lab must pass
`astrona validate` and `astrona test`.

Graders check **behaviour**, not just that an object exists: create a custom
resource and check that the API server accepts or rejects it, check that a
composite resource reaches `Ready` and owns the objects it should, check that
a provisioned workload answers a request. Many graders also reject the
plausible but wrong fix (`x-kubernetes-preserve-unknown-fields: true` to
silence a schema error, removing a finalizer by hand instead of fixing the
controller, creating the composed objects by hand instead of through the
Composition, giving a tenant `cluster-admin`). A lab's `question.md` and
`solution.md` must match what its `validation/` scripts actually check.

Test clusters on the maintainer's machine: one at a time. Podman has 10 GiB
and also runs the platform stack; parallel clusters run it out of memory.
Never touch clusters you did not create.

### Where to find trusted sources

Check facts here before writing them down. Prefer these over memory.

- **CRDs (the exam's own docs site):**
  [Custom resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/),
  [Extend the API with CRDs](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/),
  [Versions in CRDs](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/),
  [CEL in Kubernetes](https://kubernetes.io/docs/reference/using-api/cel/)
- **Controllers and operators:**
  [Controllers](https://kubernetes.io/docs/concepts/architecture/controller/),
  [Operator pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/),
  [Finalizers](https://kubernetes.io/docs/concepts/overview/working-with-objects/finalizers/),
  [Owners and dependents](https://kubernetes.io/docs/concepts/overview/working-with-objects/owners-dependents/),
  [Prometheus Operator](https://prometheus-operator.dev/docs/getting-started/introduction/)
- **Crossplane 2.4:**
  [What's Crossplane](https://docs.crossplane.io/v2.4/whats-crossplane/),
  [Composite resource definitions](https://docs.crossplane.io/v2.4/composition/composite-resource-definitions/),
  [Compositions](https://docs.crossplane.io/v2.4/composition/compositions/),
  [Providers](https://docs.crossplane.io/v2.4/packages/providers/),
  [CLI reference](https://docs.crossplane.io/v2.4/cli/command-reference/),
  [provider-kubernetes](https://github.com/crossplane-contrib/provider-kubernetes)
- **Automation frameworks:**
  [Argo Workflows](https://argo-workflows.readthedocs.io/en/latest/),
  [Workflow templates](https://argo-workflows.readthedocs.io/en/latest/workflow-templates/),
  [Argo Events](https://argoproj.github.io/argo-events/),
  [Argo CD](https://argo-cd.readthedocs.io/en/stable/)
- **Access control:**
  [RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- **The exam itself:** the CNPE page on the Linux Foundation training site
  lists the official curriculum:
  <https://training.linuxfoundation.org/certification/certified-cloud-native-platform-engineer-cnpe/>.
  The exam environment facts (Kubernetes 1.35, tasks over `ssh`, allowed
  documentation) come from
  <https://docs.linuxfoundation.org/tc-docs/certification/important-instructions-cnpe>.

### Skills to use here

The `astrona-course-*` skills do most authoring jobs in this repository: planning
(`domain-plan`), creating the tree (`domain-scaffold`), building modules
(`domain-build`), deep-dive parts (`deep-dive`), labs and playgrounds (`lab`),
lab docs (`lab-docs`), challenges (`create-challenge`), quizzes
(`generate-assessment`) and fact-checking (`review-accuracy`).
