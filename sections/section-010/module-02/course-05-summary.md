# Summary

A CustomResourceDefinition can serve a platform API through more than one version. Served versions decide which `apiVersion` values clients may use. The storage version decides which form the API server writes to etcd.

## What you learned

A CRD may have many served versions, but only one version can have `storage: true`. With `conversion.strategy: None`, the API server changes only `apiVersion` when it serves an object through another version. This works only when the versions have compatible schemas. Changing the storage version affects new writes, but old objects may still be stored in the old version, which is why `status.storedVersions` can list more than one value. The API server adds the new storage version to that list at once and never removes an old one by itself. A plain `kubectl get` uses the preferred version, which the API server picks by version priority, so `v1` wins over `v1alpha1`.

A deprecated version still works, but the API server returns a warning when a client uses it. Setting `served: false` is stronger: the API server stops accepting that version. Deprecation gives clients time to move; removal breaks clients that still name the old version.

The `status` subresource gives controllers a separate endpoint for observed state. Normal writes to the main resource update `spec` and ignore `status`; writes to `/status` update `status` and ignore `spec`. This split lets platform teams grant different RBAC for user intent and controller observation.

The `scale` subresource maps the standard Kubernetes `Scale` object to fields inside the custom resource. `specReplicasPath` points at the desired replica count, and `statusReplicasPath` points at the observed count. `kubectl scale` changes the desired count, and the schema still limits the value, but only a controller can make the real system match and then write status. The key facts to remember are these:

- Serve old and new versions together while clients move.
- Use `status.storedVersions` to see which versions may still exist in storage.
- Deprecation warns; `served: false` removes the endpoint.
- `status` and `scale` are subresources, not controllers.

<!-- astrona:playground:destroy -->
