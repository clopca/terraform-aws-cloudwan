<!-- BEGIN_TF_DOCS -->
# AWS Cloud WAN Terraform module

[![Terraform Registry](https://img.shields.io/badge/Terraform%20Registry-aws--ia%2Fcloudwan-844FBA?logo=terraform)](https://registry.terraform.io/modules/aws-ia/cloudwan/aws/latest)
[![License](https://img.shields.io/github/license/aws-ia/terraform-aws-cloudwan)](LICENSE)

This module creates or references one AWS Network Manager Global Network and one
Cloud WAN Core Network. The root module owns only the fabric boundary. Policy
deployment and AWS RAM sharing are separate submodules so permissions, cadence,
and state ownership can be selected independently.

> [!IMPORTANT]
> Upgrading from v3 requires declarative state migration. Follow
> [UPGRADE-GUIDE-4.0.md](UPGRADE-GUIDE-4.0.md) and reject every plan containing a
> delete or replacement before changing a production state.

## Usage

```hcl
module "cloudwan" {
  source  = "aws-ia/cloudwan/aws"
  version = "~> 4.0"

  global_network = {
    description = "production-global-network"
  }

  core_network = {
    description = "production-core-network"
    base_policy = {
      regions = ["us-west-2", "eu-west-1"]
    }
  }

  tags = {
    Environment = "production"
  }
}
```

The `create` selector at each boundary must be known during planning. IDs may be
computed because they do not control resource cardinality:

```hcl
module "cloudwan" {
  source  = "aws-ia/cloudwan/aws"
  version = "~> 4.0"

  global_network = {
    create = false
    id     = module.foundation.global_network_id
  }

  core_network = {
    create = false
    id     = module.foundation.core_network_id
  }
}
```

Reference mode is ID-only and owns no Network Manager resource. AWS data sources
resolve ARNs, state, edges, and segments, and a precondition verifies that the
Core Network belongs to the resolved Global Network.

## Create-only base policy

`core_network.base_policy` is available only when initially creating a Core
Network. Set exactly one of `policy_document` or `regions`. The AWS provider does
not reliably apply later changes to `create_base_policy`,
`base_policy_document`, or `base_policy_regions`; this module therefore ignores
those attributes after creation. Continuous policy changes belong in
[`modules/policy`](modules/policy).

An exact-byte approval digest can protect a document used during creation:

```hcl
core_network = {
  description = "production-core-network"
  base_policy = {
    policy_document = file("${path.module}/base-policy.json")
    approved_sha256 = var.approved_base_policy_sha256
  }
}
```

The digest proves equality only. A review pipeline must establish provenance and
approve the saved plan. Preserve the exact v3 base-policy bytes during the first
migration hop.

## Policy deployment

```hcl
module "cloudwan_policy" {
  source  = "aws-ia/cloudwan/aws//modules/policy"
  version = "~> 4.0"

  core_network_id = module.cloudwan.core_network_id
  policy_document = file("${path.module}/policy.json")
  timeouts        = { update = "60m" }
}
```

Terraform requests Put and Execute, but the provider reads LATEST and does not
prove that the desired policy is LIVE. Verify `GetCoreNetworkPolicy(Alias=LIVE)`,
the expected digest and version, successful execution, and change events outside
Terraform. See the policy submodule's verification and recovery runbook.

`live_policy_version_id` is intentionally absent because AWS provider 6.59 does
not expose an authoritative LIVE policy data source or resource attribute.

## Core Network sharing

Use [`modules/core-network-share`](modules/core-network-share) with an explicit
commercial `us-east-1` provider. Associations are maps keyed by immutable caller
identity. Version 4.0 rejects GovCloud because its RAM home-region behavior for
Core Networks is not verified, and it does not support `aws-cn`.

For one-account, one-owner deployments,
[`modules/stack`](modules/stack) composes fabric, policy, and optional sharing in
one state. It still requires separate `aws` and `aws.us_east_1` provider
configurations and the same external LIVE verification.

## Output stability

| Tier | Contract | Intended use |
|---|---|---|
| Tier 1 | Scalar IDs/ARNs, Core Network state, edges by Region, and segments by name are semver-protected. | Module composition and cross-state contracts. |
| Tier 3 | `resources` exposes created provider objects and is marked `UNSTABLE`. | Isolated escape-hatch use only; never pass it across states. |

`core_network_state` is the value from the last provider refresh, not continuous
health and not policy deployment evidence.

## Examples

| Example | Demonstrates |
|---|---|
| [`basic`](examples/basic) | Fabric plus policy in one state. |
| [`reference_core_network`](examples/reference\_core\_network) | ID-only reference mode with resolved topology. |
| [`core_network_share`](examples/core\_network\_share) | RAM sharing through an explicit `us-east-1` alias. |
| [`stack_compact`](examples/stack\_compact) | Compact facade with policy, sharing, and a compound timeout. |

All examples are ordinary Terraform configurations. Review resource ownership
and costs before apply. Tests use mocked providers and `command = plan`; they do
not call AWS or perform real applies.

## Testing

```shell
terraform init -backend=false
terraform fmt -check -recursive
terraform validate -no-color
terraform test -no-color
```

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.59, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.59, < 7.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_networkmanager_core_network.core_network](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_core_network) | resource |
| [aws_networkmanager_global_network.global_network](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkmanager_global_network) | resource |
| [terraform_data.base_policy_approval](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [terraform_data.core_global_relationship](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_networkmanager_core_network.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/networkmanager_core_network) | data source |
| [aws_networkmanager_global_network.existing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/networkmanager_global_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_core_network"></a> [core\_network](#input\_core\_network) | Core Network create-or-reference boundary. base\_policy is CREATE-ONLY. | <pre>object({<br/>    create      = optional(bool, true)<br/>    id          = optional(string)<br/>    description = optional(string)<br/>    base_policy = optional(object({<br/>      policy_document = optional(string)<br/>      regions         = optional(set(string))<br/>      approved_sha256 = optional(string)<br/>    }))<br/>    tags = optional(map(string), {})<br/>  })</pre> | n/a | yes |
| <a name="input_global_network"></a> [global\_network](#input\_global\_network) | Global Network create-or-reference boundary. create must be plan-known. | <pre>object({<br/>    create      = optional(bool, true)<br/>    id          = optional(string)<br/>    description = optional(string)<br/>    tags        = optional(map(string), {})<br/>  })</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied below resource-specific tags. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_core_network_arn"></a> [core\_network\_arn](#output\_core\_network\_arn) | Core Network ARN in create and reference modes. |
| <a name="output_core_network_edges_by_region"></a> [core\_network\_edges\_by\_region](#output\_core\_network\_edges\_by\_region) | Resolved Core Network edges keyed by AWS Region in create and reference modes. |
| <a name="output_core_network_id"></a> [core\_network\_id](#output\_core\_network\_id) | Core Network ID in create and reference modes. |
| <a name="output_core_network_segments_by_name"></a> [core\_network\_segments\_by\_name](#output\_core\_network\_segments\_by\_name) | Resolved Core Network segments keyed by segment name in create and reference modes. |
| <a name="output_core_network_state"></a> [core\_network\_state](#output\_core\_network\_state) | Core Network state from the last refresh; not continuous health and not proof that a policy is LIVE. |
| <a name="output_global_network_arn"></a> [global\_network\_arn](#output\_global\_network\_arn) | Global Network ARN in create and reference modes. |
| <a name="output_global_network_id"></a> [global\_network\_id](#output\_global\_network\_id) | Global Network ID in create and reference modes. |
| <a name="output_resources"></a> [resources](#output\_resources) | UNSTABLE Tier 3 provider-shaped escape hatch. Shape may change in any release; prefer Tier 1 outputs. |
<!-- END_TF_DOCS -->