# Cross-account Core Network sharing

This example shares one Core Network with an AWS Organization and an
organizational unit through RAM. Use it when Organizations defines the consumer
boundary and external account principals must remain disabled.

## What this demonstrates

- Commercial RAM operations through an explicit `aws.ram` provider in
  `us-east-1`.
- Organization and OU principal ARN forms under stable association keys.
- `allow_external_principals = false` for an Organizations-only boundary.
- Separate resource-share permission and Cloud WAN attachment-acceptance flows.

## Relevant configuration

The complete configuration is in [`main.tf`](./main.tf). The principal boundary
is the differential portion:

```hcl
module "share" {
  source = "../../modules/core-network-share"

  providers = { aws = aws.ram }

  resource_share = {
    name                      = "organization-cloudwan"
    allow_external_principals = false
  }

  resources = {
    core = module.cloudwan.core_network_arn
  }

  principals = {
    organization   = var.organization_arn
    application-ou = var.application_ou_arn
  }
}
```

## Prerequisites and cost

- Enable AWS RAM sharing with AWS Organizations in the management account.
- Replace the example Organization and OU ARNs with principals from the same
  commercial partition and intended Organization.
- Applying creates a two-edge fabric, RAM share, and associations. RAM has no
  additional charge; Cloud WAN edge, attachment, processing, and transfer
  charges can apply.

## Run

```shell
terraform init
terraform validate
terraform plan -out=tfplan
terraform output principal_association_ids
```

Organization principals normally avoid invitation acceptance after RAM and
Organizations integration is enabled. Cloud WAN attachment acceptance remains a
separate workflow: the consumer creates the attachment, the Core Network policy
maps it, and the designated owner accepts it when the segment requires approval.
