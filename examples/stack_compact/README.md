# Compact one-state composition

This example composes the root fabric, policy deployment, and optional Core
Network sharing directly in one state. Use it when one team owns all three
lifecycles and wants one plan without a wrapper facade.

## What this demonstrates

- Direct data flow from fabric IDs and ARNs into policy and sharing submodules.
- Provider-by-role RAM binding through `aws.ram`.
- Optional sharing whose disabled path leaves no RAM resources or associations.
- A compound `1h30m` policy update timeout.

## Relevant configuration

The complete configuration is in [`main.tf`](./main.tf). Optional sharing is the
scenario-specific composition choice:

```hcl
module "policy_deployment" {
  source = "../../modules/policy-deployment"

  core_network_id = module.fabric.core_network_id
  policy_document = local.policy_document
  timeouts        = { update = "1h30m" }
}

module "share" {
  count  = var.sharing == null ? 0 : 1
  source = "../../modules/core-network-share"

  providers      = { aws = aws.ram }
  resource_share = { name = var.sharing.name }
  resources      = { core = module.fabric.core_network_arn }
  principals     = var.sharing.principals
}
```

## Prerequisites and cost

- Terraform `>= 1.7`, AWS provider `>= 6.59`, and a commercial `us-east-1` RAM
  provider.
- Replace the default account principal before a real plan.
- Applying creates the fabric and policy; enabling sharing also creates RAM
  resources. Cloud WAN edge, attachment, processing, and transfer charges apply.

## Run

```shell
terraform init
terraform validate
terraform plan -out=tfplan
```

The `resource_share_arn` output becomes available after an approved `terraform apply tfplan`;
`terraform output` reads state, not the saved plan. Use `terraform show tfplan`
to inspect planned values without applying.

Set `sharing = null` to omit all RAM resources. Use separate states instead when
fabric ownership, policy release, and sharing have different operators,
permissions, release cadences, or failure domains.
