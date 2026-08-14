# Share a Core Network

This example creates a fabric and shares its Core Network with one AWS account
through RAM. Use it when the fabric and share live in one state but RAM operations
must use an explicit commercial home-Region provider.

## What this demonstrates

- A default provider for fabric operations and `aws.ram` in `us-east-1`.
- Stable `resources.core` and `principals.network-tools` association keys.
- A Core Network ARN passed directly from fabric outputs into the share module.
- External-principal access disabled by default.

## Relevant configuration

The complete configuration is in [`main.tf`](./main.tf). The provider binding and
share declaration are the differential portion:

```hcl
module "share" {
  source = "../../modules/core-network-share"

  providers = { aws = aws.ram }

  resource_share = {
    name = "shared-core-network"
  }

  resources = {
    core = module.cloudwan.core_network_arn
  }

  principals = {
    network-tools = "123456789012"
  }
}
```

## Prerequisites and cost

- Replace the example account ID before a real plan.
- Configure the `aws.ram` provider in commercial `us-east-1`.
- Applying creates the fabric, one RAM share, and its associations. Cloud WAN
  edge, attachment, processing, and transfer charges can apply; RAM sharing has
  no additional charge.

## Run

```shell
terraform init
terraform validate
terraform plan -out=tfplan
```

The `principal_association_ids` output becomes available after an approved `terraform apply tfplan`;
`terraform output` reads state, not the saved plan. Use `terraform show tfplan`
to inspect planned values without applying.

The share does not create or accept spoke VPC attachments. Define the attachment,
segment acceptance, and owner-account workflow separately, and never destroy an
attachment accepter as a sharing-revocation mechanism.
