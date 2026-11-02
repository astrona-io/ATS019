# Restore A Cleanup Worker

The ConfigMap `scout-settings` has a deletion timestamp but still exists. A ConfigMap stores non-secret configuration, and a finalizer keeps an object in the Kubernetes application programming interface (API) until the responsible component completes cleanup. The safe fix starts with that component, because removing its finalizer first would skip the work it protects.

## Find the component responsible for cleanup

These commands require `scout-settings` to have a deletion timestamp. Its custom finalizer is `platform.starfleet.io/cleanup`. The playground's cleanup contract is to delete `scout-cache` before releasing `scout-settings`.

An annotation records metadata on an object without acting as a selector. The annotation `platform.starfleet.io/cleanup-job` names the worker for this example. This is a playground convention, not a Kubernetes finalizer feature.

<!-- astrona:playground:renew -->

Read that annotation, the Job and its pods:

```sh
kubectl -n starfleet get configmap scout-settings -o jsonpath='{.metadata.annotations.platform\.starfleet\.io/cleanup-job}{"\n"}'
kubectl -n starfleet get job scout-cleanup -o custom-columns=NAME:.metadata.name,SUSPEND:.spec.suspend,ACTIVE:.status.active
kubectl -n starfleet get pods -l job-name=scout-cleanup
```

You should see:

```text
scout-cleanup
NAME            SUSPEND   ACTIVE
scout-cleanup   true      <none>
No resources found in starfleet namespace.
```

A Job runs a task to completion. `SUSPEND true` means the Job controller does not start its task, so there is no worker pod. The Prometheus Operator is unrelated to this finalizer. Restarting that operator would not perform this cleanup.

In a production operator, find the controller responsible for the exact finalizer name. Check whether its Deployment runs, whether its ServiceAccount has permissions, and whether its logs show a failed cleanup call. A ServiceAccount is the identity a pod uses when it sends requests to the API server. A running controller may still fail because a referenced object, permission or external service is missing.

The worker here uses the ServiceAccount `scout-cleanup`. Role-based access control (RBAC) limits the operations that an identity may perform. A Role lists permissions in one namespace, and a RoleBinding grants those permissions to an identity. The playground grants access only to the two ConfigMaps involved.

The worker can get, list and watch both named ConfigMaps. The wait operation needs list and watch as well as get. It can also delete the cache and patch the object with the finalizer. Verify those two cleanup permissions:

```sh
kubectl -n starfleet auth can-i delete configmap/scout-cache --as=system:serviceaccount:starfleet:scout-cleanup
kubectl -n starfleet auth can-i patch configmap/scout-settings --as=system:serviceaccount:starfleet:scout-cleanup
```

You should see:

```text
yes
yes
```

Both answers are `yes`. The permissions are present; the worker simply has not run. Restore its execution instead of granting broader access or clearing the finalizer from your terminal.

## Start cleanup in the right order

The Job uses init containers, which run to completion in order before its main container starts. The first waits for a deletion timestamp. The second deletes `scout-cache` and waits for deletion. Only then does the main container remove the expected finalizer with JavaScript Object Notation (JSON) Patch, a list of operations on fields in an object.

The `test` operation checks that the finalizer list contains exactly the expected key. If another finalizer appears, the patch fails rather than removing an unrelated key. The cleanup delete uses `--ignore-not-found=true`, so a retry can proceed if the cache was already removed.

Save this as `job-scout-cleanup.yaml`. It matches the installed Job's template and changes `suspend` to `false`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: scout-cleanup
  namespace: starfleet
spec:
  suspend: false
  backoffLimit: 1
  template:
    spec:
      serviceAccountName: scout-cleanup
      restartPolicy: Never
      initContainers:
        - name: wait-for-deletion
          image: registry.k8s.io/kubectl:v1.35.8
          command: ["kubectl"]
          args:
            - "-n"
            - starfleet
            - wait
            - "--for=jsonpath={.metadata.deletionTimestamp}"
            - configmap/scout-settings
            - "--timeout=60s"
          resources:
            requests: {cpu: 10m, memory: 16Mi}
            limits: {memory: 64Mi}
        - name: delete-cache
          image: registry.k8s.io/kubectl:v1.35.8
          command: ["kubectl"]
          args: ["-n", starfleet, delete, configmap, scout-cache, "--ignore-not-found=true", "--wait=true", "--timeout=60s"]
          resources:
            requests: {cpu: 10m, memory: 16Mi}
            limits: {memory: 64Mi}
      containers:
        - name: release-finalizer
          image: registry.k8s.io/kubectl:v1.35.8
          command: ["kubectl"]
          args:
            - "-n"
            - starfleet
            - patch
            - configmap
            - scout-settings
            - "--type=json"
            - "-p"
            - '[{"op":"test","path":"/metadata/finalizers","value":["platform.starfleet.io/cleanup"]},{"op":"remove","path":"/metadata/finalizers/0"}]'
          resources:
            requests: {cpu: 10m, memory: 16Mi}
            limits: {memory: 64Mi}
```

Apply it:

```sh
kubectl apply -f job-scout-cleanup.yaml
```

You should see:

```text
job.batch/scout-cleanup configured
```

Then check the result:

```sh
kubectl -n starfleet wait --for=condition=Complete job/scout-cleanup --timeout=120s
```

You should see:

```text
job.batch/scout-cleanup condition met
```

The Job reached `Complete`. Read every container's logs to check which actions actually succeeded:

```sh
kubectl -n starfleet logs job/scout-cleanup --all-containers=true
```

You should see:

```text
configmap/scout-settings condition met
configmap "scout-cache" deleted from starfleet namespace
configmap/scout-settings patched
```

The first container saw the deletion request. The second removed the cache. The main container released the finalizer only after that cleanup succeeded. Now check both ConfigMaps:

```sh
kubectl -n starfleet get configmap scout-settings scout-cache --ignore-not-found -o name
```

The command prints nothing.

The empty result proves that both cleanup and deletion finished. The API server removed `scout-settings` when its last finalizer was gone. Read the Job's conditions as a final check:

```sh
kubectl -n starfleet get job scout-cleanup -o jsonpath='{range .status.conditions[*]}{.type}{" "}{.status}{" reason="}{.reason}{"\n"}{end}'
```

You should see:

```text
Suspended False reason=JobResumed
SuccessCriteriaMet True reason=CompletionsReached
Complete True reason=CompletionsReached
```

A condition records a resource's state with a type, status and reason. Here the Job reports successful completion. If the Job fails, inspect its pods and container logs. An error in an init container prevents the main container from releasing the finalizer, which keeps the cleanup contract intact.

## When manual removal is a last resort

This worker is a one-time recovery example, not an operator that watches every object. A real operator normally handles finalization inside its reconcile loop: read the object, see deletion, perform cleanup, and remove its own key. Restore that controller or fix the failed cleanup dependency whenever possible.

Manual removal is a last resort when the responsible component cannot be restored. First identify exactly what cleanup the key protects, complete or verify that cleanup by another method, and record any resources left for a new owner. Removing a finalizer without those checks can lose the only record of resources that still need cleanup. Removing every finalizer also bypasses other components' work.

You can now diagnose a stuck deletion by identifying the finalizer owner, checking execution and permissions, and restoring cleanup in order. The example finished with both the protected resource and its cleanup target gone, so it proved more than a successful patch or a running worker pod.

## Common pitfalls

> [!WARNING]
> - **Restarting an unrelated operator.** A custom finalizer needs the component that implements that exact cleanup contract.
> - **Removing the finalizer before cleanup.** The request disappears while resources it was meant to release may remain.
> - **Checking only whether a worker pod runs.** Read the Job condition, each container's logs and the cleanup targets.
> - **Changing the Job template during recovery.** The installed template is immutable; this example changes only suspension.

## Your mission: Restore A Cleanup Worker That Cannot Finish

You can now find the component behind a finalizer, check its permissions and restore its cleanup in the right order. The mission gives you a ConfigMap that has been terminating for a long time. You find why its worker cannot finish, repair it without widening access and prove that the worker, not you, released the finalizer.

Pause the playground first:

```sh
astrona stop ats-019-playground-020-02
```

Start the lab, then submit your answer:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS019.git -c sections/section-020/module-02/labs/lab-02
astrona submit -c sections/section-020/module-02/labs/lab-02
```

When you finish, remove the lab and resume the playground:

```sh
astrona destroy ats-019-lab-020-02-02
astrona start ats-019-playground-020-02
```
