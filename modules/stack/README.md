# Compact Cloud WAN stack

This facade composes the root fabric, policy, and optional Core Network share
modules in one Terraform state. It is intended for one account and one team that
owns all three lifecycles. It does not own VPCs, firewalls, attachments, or
routes, and it does not replace the policy module's external LIVE verification.

```hcl
provider "aws" {
  region = "us-west-2"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "cloudwan" {
  source  = "aws-ia/cloudwan/aws//modules/stack"
  version = "~> 4.0"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  global_network = { description = "small-team-global" }
  core_network = {
    description = "small-team-core"
    base_policy = { policy_document = var.base_policy_document }
  }

  policy_document = var.final_policy_document
  policy_timeouts = { update = "60m" }

  sharing = {
    resource_share = { name = "small-team-core" }
    principals = {
      application-ou = var.application_ou_arn
    }
  }
}
```

Set `sharing = null` to omit every RAM resource. The caller must still pass both
provider configurations because provider aliases are a static module contract.

## Extracting policy or sharing to separate states

1. Freeze applies and capture IDs, ARNs, policy LIVE/LATEST evidence, association
   principals, tags, and provider bindings.
2. Add caller-root `removed` blocks with `destroy = false` for each resource that
   leaves this stack.
3. Add exact `import` blocks in the destination state. Policy attachment import
   uses the Core Network ID. RAM associations use
   `<share-arn>,<resource-or-principal>`.
4. Review complete saved plans under one operational lock. Reject every delete,
   replacement, or unexpected update.
5. Apply the forget and import handoff, verify LIVE externally, and require clean
   plans in both states before unfreezing writers.
