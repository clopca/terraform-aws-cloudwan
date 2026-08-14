# Core Network sharing

`modules/core-network-share` creates or references one AWS RAM resource share and
manages Core Network resource associations plus account, Organization, or
organizational-unit principal associations. Every association map key is durable
Terraform state identity.

## RAM provider by role

Cloud WAN Core Networks are global resources, while their RAM shares use the RAM
home Region. Version 4 supports sharing only in the commercial `aws` partition
with an explicit `us-east-1` provider.

```hcl
provider "aws" {
  region = "us-west-2"
}

provider "aws" {
  alias  = "ram"
  region = "us-east-1"
}

module "cloudwan_share" {
  source  = "aws-ia/cloudwan/aws//modules/core-network-share"
  version = "~> 4.0"

  providers = { aws = aws.ram }

  resource_share = { name = "production-cloudwan" }
  resources      = { core = module.cloudwan.core_network_arn }
  principals = {
    production-ou = var.production_ou_arn
    network-tools = var.network_tools_account_id
  }
}
```

The module rejects other RAM Regions, GovCloud, and `aws-cn`. GovCloud Core
Network sharing behavior is not part of the v4 contract.

## Share ownership

Create mode owns the RAM share and accepts `name`,
`allow_external_principals`, and tags. Reference mode accepts the complete share
ARN and no create-only fields. In both modes the module owns the declared
resource and principal associations.

Keep resource and principal keys stable. Changing `production-ou` to another key
changes the Terraform address even when the principal ARN is unchanged; use a
caller-owned `moved` block for a deliberate rename.

## Principal forms and acceptance

Supported principals are:

- a nonzero 12-digit AWS account ID;
- an AWS Organizations organization ARN;
- an AWS Organizations organizational-unit ARN.

Organization and OU ARNs must use the provider's effective partition. AWS RAM
sharing with Organizations must be enabled before organization-wide principals
can consume the share. Account principals outside the owning Organization may
require invitation acceptance when `allow_external_principals = true`.

The share establishes permission to associate with the Core Network. It does not
create spoke VPC attachments or accept attachment proposals. The Core Network
policy, attachment tags, segment acceptance settings, and owner-account workflow
still control attachment admission.

## Attachment accepter destruction warning

> [!CAUTION]
> Destroying `aws_networkmanager_attachment_accepter` calls `DeleteAttachment`.
> It deletes the spoke-owned attachment; it is not a harmless approval removal.

Use a non-destructive state handoff before moving or retiring an accepter:

```hcl
removed {
  from = module.attachment_accepters.aws_networkmanager_attachment_accepter.this["spoke"]

  lifecycle {
    destroy = false
  }
}
```

Then:

1. Save and review the old-state forget plan and the destination import plan.
2. Apply the old-state forget first.
3. Verify through AWS read APIs that the same attachment ID still exists.
4. Import or otherwise adopt that exact attachment ID in the destination state.
5. Verify owner account, Core Network, segment, and attachment state from both
   account perspectives.
6. Require clean plans before removing transitional blocks.

Never destroy an accepter to revoke sharing or transfer ownership.

## Sharing checklist

- Bind the share module to a commercial `us-east-1` provider named by role.
- Assign one owner to the share and every association.
- Keep association keys immutable or move state explicitly.
- Confirm AWS Organizations RAM integration before using organization principals.
- Document invitation and attachment-acceptance owners for cross-account paths.
- Transfer accepter state with `destroy = false`; never use normal destroy.
