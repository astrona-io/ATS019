# Solution Walkthrough

You work from the terminal as the tenant of the `outpost` namespace. You apply
one `TeamEnvironment`, wait for it, and check what Crossplane built. You never
create the Deployment or the Service yourself, and you change no other object.

| Goal | Where it lives | Command |
| --- | --- | --- |
| Ask for the environment | A `TeamEnvironment` in `outpost` | `kubectl apply -f teamenvironment-scout-env.yaml` |
| Know that it works | `Synced` and `Ready` conditions on the request | `kubectl -n outpost wait ... --for=condition=Ready` |
| See what Crossplane built | `spec.crossplane.resourceRefs` and the Deployment | `kubectl -n outpost get ...` |
| Prove the behaviour | A request from `shuttle` | `kubectl -n outpost exec deploy/shuttle -- curl ...` |

## The feedback loop

Grading runs from the terminal on your own machine, where you typed
`astrona run`. Run it after every step:

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

The checks are `request`, `ready`, `composed-resources`, `workload` and
`answers`. All of them fail at the start, because no request exists.

---

## Step 1: Look at the starting state

Check that the platform API exists and that the request does not:

```sh
kubectl get xrd teamenvironments.platform.starfleet.io
kubectl get composition
kubectl -n outpost get teamenvironment
```

The first two commands show the XRD and the Composition `teamenvironment`. The
last command finds no `TeamEnvironment`. No check turns green in this step.

---

## Step 2: Request the environment

Save this as `teamenvironment-scout-env.yaml`:

```yaml
apiVersion: platform.starfleet.io/v1alpha1
kind: TeamEnvironment
metadata:
  name: scout-env
  namespace: outpost
spec:
  team: outpost
  size: medium
  replicas: 2
```

- `apiVersion` and `kind` name the platform API that the XRD defines.
- `metadata.namespace` puts the request in the tenant namespace. A namespaced
  composite resource creates its objects for the namespace it lives in.
- `spec.team`, `spec.size` and `spec.replicas` are the values from the task.

Apply it:

```sh
kubectl apply -f teamenvironment-scout-env.yaml
```

**Run the check.** The check `request` passes.

---

## Step 3: Wait for Ready

Crossplane works after the command returns, so wait for the condition:

```sh
kubectl -n outpost wait teamenvironment/scout-env --for=condition=Ready --timeout=300s
kubectl -n outpost get teamenvironment scout-env
```

The `wait` command returns when `Ready` is `True`. The table shows `True` in the
`SYNCED` and `READY` columns. The first start can take a few minutes, because
the provider creates the Deployment and the pods must pull their image.

**Run the check.** The checks `ready` and `composed-resources` pass.

---

## Step 4: Check the Deployment and prove that it answers

Read the replicas and the team label of the Deployment that Crossplane built:

```sh
kubectl -n outpost get deployment scout -o jsonpath='{.spec.replicas}{"  "}{.status.availableReplicas}{"  "}{.spec.template.metadata.labels.team}{"\n"}'
```

You should see the numbers `2` and `2` and the word `outpost`. Now send a
request from `shuttle` and print only the HTTP status code:

```sh
kubectl -n outpost exec deploy/shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://scout:9898
```

You should see `200`. If you see `000`, the pods are still starting. Run the
command again after a few seconds.

**Run the check.** The checks `workload` and `answers` pass.

---

## Step 5: Submit

When all five checks are green, submit:

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

---

## If a check stays red

- **`request` fails and says the values differ.** The request has the wrong
  `size`, `replicas` or `team`. Change the file and apply it again.
- **`request` fails and says no TeamEnvironment exists.** You applied the file
  in another namespace. Check `metadata.namespace`, delete the wrong object and
  apply the file again.
- **`ready` fails.** Crossplane is not finished. Wait and run the check again.
  If `Ready` stays `False` for minutes, read `kubectl -n outpost describe
  teamenvironment scout-env`.
- **`composed-resources` fails and says fewer than 2 references.** The workload
  did not come from the Composition. Delete any Deployment or Service that you
  created by hand, and let Crossplane create them.
- **`workload` fails.** The Deployment must have 2 available replicas. Wait for
  the pods, and do not edit the Deployment. Crossplane resets hand edits.
- **`answers` fails with a status other than `200`.** Wait for the pods and send
  the request again.
