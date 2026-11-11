# Solution Walkthrough

The lesson's two ClusterRoles supply the missing rules. Save them as `teamenvironment-roles.yaml`, using `aggregate-to-edit: "true"` on the write role and `aggregate-to-view: "true"` on the read role. Their API group is `platform.starfleet.io` and resource is `teamenvironments`.

```sh
kubectl apply -f teamenvironment-roles.yaml
kubectl get clusterrole edit view -o yaml
kubectl auth can-i create teamenvironments.platform.starfleet.io -n outpost --as=platform-editor
kubectl auth can-i list teamenvironments.platform.starfleet.io -n outpost --as=platform-reader
kubectl auth can-i create teamenvironments.platform.starfleet.io -n outpost --as=platform-reader
kubectl auth can-i get secrets -n outpost --as=platform-reader
kubectl auth can-i list teamenvironments.platform.starfleet.io -n starfleet --as=platform-editor
```

After aggregation converges, the first two permission checks return `yes`; the remaining checks return `no`. A ClusterRole defines reusable permissions. The existing namespaced RoleBindings restrict where these identities receive them. The reference manifests are in `solution/roles.yaml`.

Use `astrona submit --watch` from the host to check progress without ending the lab. Inspect both allowed and denied checks before submitting the final attempt.
