# Printer Columns, Short Names And Categories

A platform team checks its custom resources many times a day, often during an incident. If every check needs `-o yaml` and a scroll, the important fields get missed. This part makes `kubectl get` show the fields that matter, gives the type a short name, and puts it in a category, so the API is quick to read from the command line.

## What kubectl get shows for a custom resource

For a built-in type such as a Deployment, `kubectl get` shows columns like `READY` and `UP-TO-DATE`. Those columns come from the API server, not from `kubectl`. For a custom resource, the API server shows a name and an age unless the CRD lists more columns in `additionalPrinterColumns`.

Each printer column has a `name` (the header), a `type` (`string`, `integer`, `number`, `boolean` or `date`) and a `jsonPath` into the object. A column of type `date` is shown as an age, such as `48s`. A column can also have a `priority`: `0`, the default, is always shown, and a higher number is shown only with `-o wide`.

## Add the columns, a short name and a category

<!-- astrona:playground:renew -->

Update `crd-teamenvironment.yaml`. It keeps the schema and both CEL rules, and adds `shortNames` and `categories` under `names`, and `additionalPrinterColumns` in the version. Save this as `crd-teamenvironment.yaml`:

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: teamenvironments.platform.starfleet.io
spec:
  group: platform.starfleet.io
  scope: Namespaced
  names:
    kind: TeamEnvironment
    plural: teamenvironments
    singular: teamenvironment
    shortNames:
      - teamenv
    categories:
      - platform
  versions:
    - name: v1alpha1
      served: true
      storage: true
      additionalPrinterColumns:
        - name: Team
          type: string
          jsonPath: .spec.team
        - name: Size
          type: string
          jsonPath: .spec.size
        - name: Replicas
          type: integer
          jsonPath: .spec.replicas
        - name: Age
          type: date
          jsonPath: .metadata.creationTimestamp
      schema:
        openAPIV3Schema:
          type: object
          required:
            - spec
          properties:
            spec:
              type: object
              required:
                - team
                - size
                - contact
              x-kubernetes-validations:
                - rule: "self.size != 'small' || self.replicas <= 2"
                  message: "a small environment runs at most 2 replicas"
              properties:
                team:
                  type: string
                  minLength: 1
                  maxLength: 30
                  x-kubernetes-validations:
                    - rule: "self == oldSelf"
                      message: "team cannot be changed after creation"
                size:
                  type: string
                  enum:
                    - small
                    - medium
                    - large
                replicas:
                  type: integer
                  minimum: 1
                  maximum: 5
                  default: 1
                contact:
                  type: string
                  pattern: '^[a-z0-9.-]+@[a-z0-9.-]+$'
                retentionDays:
                  type: integer
                  minimum: 1
                  maximum: 90
                  default: 7
```

Once you list `additionalPrinterColumns`, the API server stops adding the `Age` column by itself, so the file adds it back as the last column. `shortNames` lists extra names `kubectl` accepts for the type, and `categories` puts the type in a named group.

Apply it, then list the objects with the short name:

```sh
kubectl apply -f crd-teamenvironment.yaml
kubectl -n outpost get teamenv
```

You should see something like:

```text
customresourcedefinition.apiextensions.k8s.io/teamenvironments.platform.starfleet.io configured
NAME    TEAM      SIZE     REPLICAS   AGE
alpha   outpost   small    2          48s
beta    outpost   medium   1          48s
delta   outpost   small    1          35s
gamma   outpost   huge     3          48s
zeta    outpost   small    1          23s
```

One line now answers the questions that took a `-o yaml` per object before. It also makes a problem jump out: `gamma` still has size `huge`, the value that validation ratcheting kept because nobody changed it. The `REPLICAS` column of `beta` shows `1`, the default, which is the only value a reader of that object will ever see.

## Categories and discovery

A category lets one `kubectl get` list several types at once. Built-in types use the category `all`, which is why `kubectl get all` lists pods, Services and Deployments. A platform team can give all of its own types one category:

```sh
kubectl get platform -A
```

You should see something like:

```text
NAMESPACE   NAME    TEAM      SIZE     REPLICAS   AGE
outpost     alpha   outpost   small    2          48s
outpost     beta    outpost   medium   1          48s
outpost     delta   outpost   small    1          35s
outpost     gamma   outpost   huge     3          48s
outpost     zeta    outpost   small    1          23s
```

With one type in the category, the result matches `get teamenv`. As the platform adds more types with the same category, this one command lists all of them. Do not add custom types to `all`: other people's scripts use `kubectl get all` and do not expect your objects.

`kubectl api-resources` shows the names `kubectl` now knows for the group, and it is the quickest way to find the short name of a type you did not write:

```sh
kubectl api-resources --api-group=platform.starfleet.io
```

You should see:

```text
NAME               SHORTNAMES   APIVERSION                       NAMESPACED   KIND
teamenvironments   teamenv      platform.starfleet.io/v1alpha1   true         TeamEnvironment
```

You can now make a custom resource readable from the command line: printer columns that show the key fields, a short name that saves typing, and a category that groups a platform's types. The CRD you built refuses bad input, fills in defaults, enforces rules across fields and over time, and shows its state in one line. What it cannot do yet is change its API without breaking the objects already stored.

## Common pitfalls

> [!WARNING]
> - **Forgetting the `Age` column.** Listing any printer column turns off the default `Age` column; add it back with `type: date` and `.metadata.creationTimestamp`.
> - **Pointing a column at a field that is missing.** The column is simply empty, with no error. Check every `jsonPath` with `kubectl get -o jsonpath`.
> - **Picking a short name that is already taken.** Two types with the same short name make `kubectl` pick one of them. Check `kubectl api-resources` first.
> - **Adding a custom type to the `all` category.** It changes what `kubectl get all` returns for everyone.
