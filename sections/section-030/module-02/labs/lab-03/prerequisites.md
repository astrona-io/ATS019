# Prerequisites

You need to know how to read the conditions and events of a Crossplane
composite resource (XR) and how a Composition names its function with
`functionRef`. You should know how a Kubernetes Service selects pods with a
label selector, and how to list its endpoints.

The lab environment starts with Crossplane 2.4.2, the `provider-kubernetes`
provider and the `function-patch-and-transform` function installed. The XRD,
a request and a Composition are already applied. The cluster needs outbound
internet during the start, and the start can take several minutes.

Work in a new, empty folder on your machine and run every command from there.
