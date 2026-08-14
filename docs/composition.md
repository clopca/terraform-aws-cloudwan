# Composition patterns

The root, policy-deployment, and core-network-share modules are independent
lifecycle boundaries. They can live in separate states or compose directly in
one root without a facade module.

## Compact one-state composition

```hcl
provider "aws" {
  region = "us-west-2"
}

provider "aws" {
  alias  = "ram"
  region = "us-east-1"
}

module "fabric" {
  source  = "aws-ia/cloudwan/aws"
  version = "~> 4.0"

  global_network = { description = "production-global-network" }
  core_network = {
    description = "production-core-network"
    base_policy = { regions = ["us-west-2", "eu-west-1"] }
  }
}

module "policy" {
  source  = "aws-ia/cloudwan/aws//modules/policy-deployment"
  version = "~> 4.0"

  core_network_id = module.fabric.core_network_id
  policy_document = file("${path.module}/policy.json")
  timeouts        = { update = "60m" }
}

module "share" {
  source  = "aws-ia/cloudwan/aws//modules/core-network-share"
  version = "~> 4.0"

  providers      = { aws = aws.ram }
  resource_share = { name = "production-cloudwan" }
  resources      = { core = module.fabric.core_network_arn }
  principals     = var.ram_principals
}
```

This gives one plan and one state while preserving visible ownership boundaries.
Use separate states when fabric creation, policy release, and sharing have
different operators, permissions, review cadence, or failure domains.

## Providers by role

Use provider aliases to communicate responsibility rather than geography alone:

| Provider role | Region | Used by |
|---|---|---|
| Default fabric/policy provider | Deployment Region | Root fabric and policy deployment |
| `aws.ram` | `us-east-1` | Commercial Core Network RAM sharing |
| Attachment-owner aliases | Spoke or owner account Region | Caller-owned attachment workflows outside this module |

Pass provider bindings explicitly at module call sites. Avoid hidden inherited
aliases in wrappers because they make cross-account plans and state handoffs
harder to audit.

## Separate-state composition

Use only stable outputs between states:

- fabric state publishes `fabric_handle`, `core_network_id`, and
  `core_network_arn`;
- policy state consumes `core_network_id`;
- sharing state consumes `core_network_arn`;
- regional network states consume the Core Network ID or ARN required by their
  attachment owner.

Do not export provider-shaped resource objects. Preserve the
`fabric_handle.schema_version` check when transporting the complete handle.

A cross-state ownership transfer must preserve one physical owner at every step.
The old state forgets with `destroy = false` before the destination imports the
same ID or ARN. Keep both backends locked and verify physical identity between
steps.

## VPC attachments belong with the VPC topology

This module deliberately does not create VPCs, attachment subnets, route tables,
or Cloud WAN VPC attachments. Compose those resources with
[`aws-ia/vpc/aws` v5](https://registry.terraform.io/modules/aws-ia/vpc/aws/latest).
Its attachment guide documents subnet roles, acceptance ownership, and route
creation:

- [VPC v5 attachment documentation](https://github.com/aws-ia/terraform-aws-vpc/blob/main/docs/attachments.md)
- [VPC v5 module](https://registry.terraform.io/modules/aws-ia/vpc/aws/latest)

The Cloud WAN fabric owner publishes a Core Network handle. Each VPC owner uses
that handle with its own VPC, subnets, and routing state. Cross-account
acceptance remains an explicit owner-account workflow; a RAM share alone does
not make an attachment usable.

## Composition checklist

- Choose one state only when ownership and release cadence genuinely align.
- Use stable scalar or versioned-handle outputs across states.
- Name provider aliases by operational role and pass them explicitly.
- Keep RAM operations in the supported home Region.
- Assign VPC attachment and route ownership to the VPC topology state.
- Preserve one physical owner during every state handoff.
- Verify policy LIVE state and attachment acceptance outside Terraform before
  declaring the composed path ready.
