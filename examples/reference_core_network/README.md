# Reference an existing fabric

This example references an existing Global Network and Core Network by ID. Use it
when another state owns the fabric and consumers need normalized topology and
composition outputs without adopting lifecycle.

## What this demonstrates

- Plan-known `create = false` selectors with IDs supplied as ordinary values.
- ID-only reference mode with no create-only descriptions, tags, or base policy.
- Relationship validation between the resolved Core Network and Global Network.
- Stable ARNs, Region-keyed edge records, and `fabric_handle` output shapes.

## Relevant configuration

The complete configuration is in [`main.tf`](./main.tf). The ownership boundary
is the only scenario-specific declaration:

```hcl
module "cloudwan" {
  source = "../.."

  global_network = {
    create = false
    id     = var.global_network_id
  }

  core_network = {
    create = false
    id     = var.core_network_id
  }
}
```

## Prerequisites and cost

- Replace both placeholder IDs with resources from the same fabric.
- Grant read access to Network Manager in the selected account.
- This configuration creates no Network Manager resources, but the referenced
  fabric continues to incur its existing Cloud WAN charges.

## Run

```shell
terraform init
terraform validate
terraform plan
terraform output core_network_edges_by_region
```

A static or mocked plan proves the reference contract only. For a real plan,
compare the resolved IDs, ARNs, relationship, edges, and segments with the
external fabric owner's inventory.
