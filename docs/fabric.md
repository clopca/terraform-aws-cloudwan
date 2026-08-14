# Fabric ownership and references

The root module owns or references one AWS Network Manager Global Network and one
Cloud WAN Core Network. Explicit `create` selectors decide Terraform cardinality,
so IDs may come from upstream resources without making the plan shape unknown.

## Valid ownership combinations

| Global Network | Core Network | Valid | Reason |
|---|---|---:|---|
| Create | Create | Yes | The new Core Network is created inside the new Global Network. |
| Reference | Create | Yes | The module creates a new Core Network inside an existing Global Network. |
| Reference | Reference | Yes | Both objects remain externally owned and their relationship is verified. |
| Create | Reference | No | An existing Core Network cannot belong to a Global Network that does not yet exist. |

Create mode accepts descriptions, tags, and a create-only Core Network base
policy. Reference mode accepts only the relevant ID and rejects create-only
fields.

```hcl
module "existing_fabric" {
  source  = "aws-ia/cloudwan/aws"
  version = "~> 4.0"

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

Reference mode reads both resources, confirms that the Core Network belongs to
the resolved Global Network, and returns the same stable output shapes as create
mode. It does not adopt resource lifecycle.

## Create-only base policy

`core_network.base_policy` is an initialization boundary. Set exactly one of:

- `regions` for a minimal base policy with Cloud WAN edges in those Regions;
- `policy_document` for exact service-native policy JSON.

The AWS provider does not reliably apply later changes to the Core Network
resource's base-policy fields, so the module ignores those fields after creation.
Use [`modules/policy-deployment`](../modules/policy-deployment) for every
subsequent policy deployment.

An optional digest protects exact document bytes:

```hcl
core_network = {
  description = "production-core-network"
  base_policy = {
    policy_document = file("${path.module}/base-policy.json")
    approved_sha256 = var.approved_base_policy_sha256
  }
}
```

The digest proves byte equality. It does not prove source provenance, review, or
that the policy is LIVE.

## Stable fabric handle

`fabric_handle` packages related IDs and ARNs under a versioned schema:

```text
{
  schema_version = "cloudwan-fabric-handle/v1"
  global_network = { id = string, arn = string }
  core_network   = { id = string, arn = string }
}
```

Use it when a consumer needs both boundaries and must not accidentally combine a
Global Network from one fabric with a Core Network from another. Consumers that
need only one identifier should prefer the scalar output.

Topology outputs preserve semantic keys:

- `core_network_edges_by_region` is keyed by AWS Region;
- `core_network_segments_by_name` is keyed by segment name;
- `core_network_state` is the value from the last provider refresh.

The state output is not continuous health and is not evidence that a policy
version is LIVE.

## Ownership checklist

- Keep `create` selectors literal or otherwise plan-known.
- Preserve the module call and caller-owned map keys after deployment.
- Treat create-to-reference as a state handoff, not a boolean toggle.
- Use `removed { lifecycle { destroy = false } }` before releasing ownership of
  a physical resource that must survive.
- Verify related IDs and ARNs before adopting reference mode.
- Send ongoing policy changes through the policy-deployment submodule.
