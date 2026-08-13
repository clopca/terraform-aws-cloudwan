# Cloud WAN Core Network share

This module owns or references one AWS RAM resource share and manages Core
Network resource associations and account, Organization, or OU principal
associations by stable caller-provided keys.

Cloud WAN Core Networks are global resources, but AWS RAM sharing is regional.
Version 4.0 supports only the commercial `aws` partition and requires an AWS
provider configured in `us-east-1`. GovCloud sharing is not verified and is
therefore rejected; `aws-cn` is unsupported.

```hcl
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "cloudwan_share" {
  source  = "aws-ia/cloudwan/aws//modules/core-network-share"
  version = "~> 4.0"

  providers = { aws = aws.us_east_1 }

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
