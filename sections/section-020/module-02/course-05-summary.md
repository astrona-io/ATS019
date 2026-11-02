# Summary

Owner references record lifecycle relationships between Kubernetes objects. The garbage collector follows those references when owners disappear. It uses each owner's unique identifier, so a new object with the same name is a different owner. Labels help you select objects but do not cause cascading deletion.

## What you learned

Background deletion allows dependent cleanup to finish after the owner disappears. Foreground deletion keeps the owner while known dependents with `blockOwnerDeletion: true` are removed. Orphan deletion preserves dependents and removes their reference to that owner. Each choice has a different cleanup responsibility. The client's wait option does not change that policy.

Finalizers keep an object visible after a delete request. The deletion timestamp proves that deletion started; the remaining finalizer names show which cleanup is still required. A ConfigMap table does not show a terminating status, so read its metadata. Once deletion begins, you cannot add a finalizer or make the object active again.

The component responsible for a finalizer must finish its cleanup before removing its key. Diagnose its execution, permissions and failed dependencies. The cleanup worker demonstrated the order: observe deletion, remove the cleanup target, then release the finalizer. Verify that the protected object and cleanup targets are gone, not just that a patch succeeded. Manual finalizer removal is a last resort after the protected cleanup has been completed or verified by another method.

<!-- astrona:playground:destroy -->
