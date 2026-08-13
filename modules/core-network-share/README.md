# Cloud WAN Core Network share

This module owns or references one AWS RAM resource share and manages Core
Network resource associations and account, Organization, or OU principal
associations by stable caller-provided keys.

Cloud WAN Core Networks are global resources, but AWS RAM sharing is regional.
Version 4.0 supports only the commercial `aws` partition and requires an AWS
provider configured in `us-east-1`. GovCloud sharing is not verified and is
therefore rejected; `aws-cn` is unsupported. Organization and OU principal ARNs
must use the effective provider partition.

```hcl
provider "aws" {
  alias  = "ram"
  region = "us-east-1"
}

module "cloudwan_share" {
  source  = "aws-ia/cloudwan/aws//modules/core-network-share"
  version = "~> 4.0"

  providers = { aws = aws.ram }

  resource_share = { name = "production-cloudwan" }

  resources = {
    core = module.cloudwan.core_network_arn
  }

  principals = {
    production-ou = var.production_ou_arn
    network-tools = var.network_tools_account_id
  }
}
```

Map keys are Terraform state identity. Do not rename them without caller-owned
`moved` blocks. Reference mode requires the complete existing share ARN and
forbids create-only settings.

> [!CAUTION]
> An `aws_networkmanager_attachment_accepter` is destructive on removal:
> destroying it calls `DeleteAttachment` and deletes the attachment created by
> the spoke account. Before moving or retiring an accepter, use an address that
> matches your configuration and apply a non-destructive state handoff:
>
> ```hcl
> removed {
>   from = module.attachment_accepters.aws_networkmanager_attachment_accepter.this["spoke"]
>   lifecycle {
>     destroy = false
>   }
> }
> ```
>
> Adopt the same attachment ID in the destination state, verify ownership from
> both accounts, and only then remove the old accepter configuration. Never use a
> normal destroy as an approval-revocation mechanism.
