# Question

Solve this question on: `terminal`

The `outpost` team asked the platform team for its own Prometheus server. The platform team created the `Prometheus` resource `tenant` in the namespace `outpost`. Days later, the server does not exist: `kubectl -n outpost get prometheus tenant` shows no ready replica.

The Prometheus Operator runs in the namespace `default` and is healthy. The tenant's resource sets `additionalScrapeConfigs` to the key `jobs.yaml` of the Secret `tenant-scrape`, so the tenant can scrape the `scout` Service. In the namespace `outpost` the ServiceAccount `prometheus` already has read access to Services, Endpoints and Pods. Find every reason the server does not run and repair each one. Do not delete the `Prometheus` resource, and do not create pods or StatefulSets yourself.

When you finish, these must be true:

- The Secret `tenant-scrape` exists in `outpost`. Its key `jobs.yaml` holds one scrape job with `job_name: scout-extra` that targets `scout.outpost.svc:9898`.
- The `Prometheus` resource `tenant` still reads `jobs.yaml` from the Secret `tenant-scrape`. You must not remove `additionalScrapeConfigs`.
- The conditions `Reconciled` and `Available` of `tenant` both have status `True`, and the `observedGeneration` of `Reconciled` equals `metadata.generation`.
- The pod `prometheus-tenant-0` is ready and runs as a ServiceAccount that may `get`, `list` and `watch` Pods, Services and Endpoints in `outpost`.
- That ServiceAccount may not create Deployments in `outpost`, and it is not bound to `cluster-admin`.
