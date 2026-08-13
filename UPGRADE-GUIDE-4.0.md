# Upgrade from Cloud WAN v3 to v4

Version 4 separates fabric, policy, RAM sharing, and regional topology ownership.
A zero-destroy migration is possible only when a catalog generated from the
caller's refreshed state proves the exact physical mapping. It is not a generic
guarantee.

## Preconditions

- Use Terraform 1.7 or newer and AWS provider 6.59 or newer.
- Converge the v3 configuration and save a normal full plan with refresh; do not
  use `-target`.
- Freeze every Cloud WAN policy writer and record LIVE and LATEST policy version
  IDs, digests, change-set state, and failed events.
- Export a state inventory of addresses, IDs, ARNs, principals, tags, and provider
  bindings.
- Back up the state and rehearse with a copy before touching the authoritative
  backend.
- Reject any plan action containing `delete`, including replacements.

## Ownership configuration

| v3 ownership | First v4 configuration |
|---|---|
| Global Network managed by this module | `global_network.create = true`; keep the historical `[0]` address. |
| Global Network referenced | `create = false` with the same Global Network ID. |
| Core Network managed by this module | `core_network.create = true`; keep the historical `[0]` address and exact base policy. |
| Core Network referenced | `create = false` with the same Core Network ID. |
| Intentional managed-to-reference handoff | First add `removed { destroy = false }`; only then change `create` to false. |

Changing `create=true` to `false` without a non-destructive handoff proposes a
destroy and is forbidden.

## Generic address catalog

The two root singleton addresses remain unchanged:

```text
module.cloudwan.aws_networkmanager_global_network.global_network[0]
module.cloudwan.aws_networkmanager_core_network.core_network[0]
```

No `moved` block is required for those resources when the same module call keeps
ownership. The remaining v3 resources move to explicit owners:

| v3 address pattern | v4 owner/address pattern | Migration action |
|---|---|---|
| `module.cloudwan.aws_networkmanager_core_network_policy_attachment.policy_attachment[0]` | `module.cloudwan_policy.aws_networkmanager_core_network_policy_attachment.this` | `moved` in the same state, or `removed` plus import by Core Network ID across states. |
| `module.cloudwan.aws_ram_resource_share.resource_share[0]` | `module.cloudwan_share.aws_ram_resource_share.this[0]` | `moved` in the same state, or `removed` plus import by share ARN. |
| `module.cloudwan.aws_ram_resource_association.resource_association[0]` | `module.cloudwan_share.aws_ram_resource_association.this["core"]` | `moved` after verifying the physical Core Network ARN; import ID is `<share-arn>,<resource-arn>`. |
| `module.cloudwan.aws_ram_principal_association.principal_association[N]` | `module.cloudwan_share.aws_ram_principal_association.this["<caller-key>"]` | One exact `moved` per state-observed principal; import ID is `<share-arn>,<principal>`. Never infer `N` from current HCL order. |
| `module.cloudwan.module.central_vpcs["<key>"]` | Versioned central-VPC successor selected by its migration guide | Keep on v3 until that successor is published; then use one exact module move per key. |
| `module.cloudwan.module.network_firewall["<key>"]` | Versioned firewall composition owner selected by its migration guide | Keep on v3 until the destination contract is published; move one exact key at a time. |
| `module.cloudwan.aws_route_table.igw_route_table["<key>"]` | Regional central-VPC owner | Cross-state `removed`/import or exact caller-root move after destination address and provider are fixed. |
| `module.cloudwan.aws_route_table_association.igw_route_table_association["<key>"]` | Regional central-VPC owner | Same as its route table; preserve gateway and route-table IDs. |
| `module.cloudwan.module.public_subnet_cidrs["<key>"]` | Removed calculation helper | No physical resource exists; remove only after the successor owns equivalent typed outputs. |
| `ipv4_network_definition`, root RAM inputs, `central_vpcs`, and `aws_network_firewall` | Removed root inputs | Re-home values with their new owner; there is no compatibility alias in v4. |

There are no wildcard moves. Every map key and count index must come from the
refreshed physical state.

## Same-state extraction

```hcl
moved {
  from = module.cloudwan.aws_networkmanager_core_network_policy_attachment.policy_attachment[0]
  to   = module.cloudwan_policy.aws_networkmanager_core_network_policy_attachment.this
}

moved {
  from = module.cloudwan.aws_ram_resource_share.resource_share[0]
  to   = module.cloudwan_share.aws_ram_resource_share.this[0]
}

moved {
  from = module.cloudwan.aws_ram_resource_association.resource_association[0]
  to   = module.cloudwan_share.aws_ram_resource_association.this["core"]
}

# Generate one block per physical state entry.
moved {
  from = module.cloudwan.aws_ram_principal_association.principal_association[0]
  to   = module.cloudwan_share.aws_ram_principal_association.this["production-ou"]
}
```

Before accepting the RAM principal move, compare the source state's principal
value with the destination map value. A mismatch replaces a ForceNew association
and fails the migration gate.

## Cross-state handoff

The old state forgets resources without destroying them:

```hcl
removed {
  from = module.cloudwan.aws_networkmanager_core_network_policy_attachment.policy_attachment[0]
  lifecycle { destroy = false }
}
```

The destination state adopts the same object:

```hcl
import {
  to = module.cloudwan_policy.aws_networkmanager_core_network_policy_attachment.this
  id = var.core_network_id
}
```

Use these import IDs:

| Resource | Import ID |
|---|---|
| Policy attachment | Core Network ID |
| RAM resource share | Share ARN |
| RAM resource association | `<share-arn>,<resource-arn>` |
| RAM principal association | `<share-arn>,<principal>` |

A cross-state handoff is not transactional. Review both saved plans under one
operational lock and apply the forget/import pair before unfreezing writers.
Policy import reads LATEST, not authoritative LIVE; compare LIVE externally
before and after the handoff.

## Preserve the create-only base policy

The first v4 configuration for a managed Core Network must reproduce the exact
v3 base-policy document captured from configuration/state, together with
provider binding, description, tags, and default tags. Do not derive a new base
policy from a semantically similar final policy. Remove the migration bridge only
in a later, separately reviewed change; v4 ignores later base-policy mutations by
design.

## Plan JSON gate

Convert every saved plan with `terraform show -json`. Fail the migration if any
resource action contains `delete`, or if a create, update, forget, or import is
not in the caller's exact allowlist. Compare before/after IDs, ARNs, principals,
provider bindings, tags, base-policy digest, and LIVE policy digest. Preserve the
binary plan, JSON, allowlist, identity manifest, and post-apply evidence.

After apply, verify all physical identities and `GetCoreNetworkPolicy(Alias=LIVE)`,
inspect failed change events, refresh every state, and require clean plans.

## CAUTION: attachment accepter removal deletes the spoke attachment

Destroying `aws_networkmanager_attachment_accepter` invokes
`DeleteAttachment`; it deletes the attachment created in the spoke account. It
must not be used to revoke approval or to move state. Handoff the accepter
without destroying the remote object:

```hcl
removed {
  from = module.attachment_accepters.aws_networkmanager_attachment_accepter.this["spoke"]
  lifecycle {
    destroy = false
  }
}
```

Save and inspect the old-state plan first; it must contain only the non-destructive
forget action. Then plan the destination state with an `import` block targeting
the same attachment ID. Apply old-state forget before new-state adoption, verify
the attachment ID and owner account from both states, and only then remove the
transitional blocks. If the destination cannot import, restore the old state from
the backup before any further change; never run a normal destroy.

## Appendix: caller-owned singleton wrappers

Callers that did not use the published v3 module do not match the generic catalog.
For example, an LDA-like wrapper uses singleton addresses without `[0]` and needs
caller-root moves such as:

```hcl
moved {
  from = module.cloudwan.aws_networkmanager_global_network.this
  to   = module.cloudwan.aws_networkmanager_global_network.global_network[0]
}

moved {
  from = module.cloudwan.aws_networkmanager_core_network.this
  to   = module.cloudwan.aws_networkmanager_core_network.core_network[0]
}
```

Its policy singleton likewise moves to the policy submodule or uses a cross-state
handoff. The complete caller-specific catalog must be generated from that
wrapper's real state; the design evidence is documented in the RFC v2 migration
appendix, `analysis/cloudwan-deep/experts/E3-state-migration.md`, and is not a
substitute for inspecting the caller backend.
