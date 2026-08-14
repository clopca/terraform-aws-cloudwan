<!-- BEGIN_TF_DOCS -->
# AWS Cloud WAN Module

[![Terraform Registry](https://img.shields.io/badge/Terraform%20Registry-aws--ia%2Fcloudwan-844FBA?logo=terraform)](https://registry.terraform.io/modules/aws-ia/cloudwan/aws/latest)
[![CI](https://github.com/aws-ia/terraform-aws-cloudwan/actions/workflows/ci.yml/badge.svg)](https://github.com/aws-ia/terraform-aws-cloudwan/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/aws-ia/terraform-aws-cloudwan)](LICENSE)

This module creates or references an AWS Network Manager Global Network and
Cloud WAN Core Network, deploys Core Network policies through a dedicated
submodule, and shares Core Networks through AWS Resource Access Manager (RAM).
The boundaries can use separate providers, permissions, states, and release
cadences while composing through stable IDs, ARNs, and `fabric_handle`.

> [!IMPORTANT]
> Upgrading from v3? Follow [UPGRADE-GUIDE-4.0.md](UPGRADE-GUIDE-4.0.md) before
> changing configuration or state. Reject any migration plan that deletes or
> replaces an existing fabric, policy attachment, share, or association.

## Navigation

- [Key capabilities](#key-capabilities)
- [Cost warning](#cost-warning)
- [Quick start](#quick-start)
- [Documentation](#documentation)
- [Examples](#examples)
- [Operational boundaries](#operational-boundaries)
- [Testing](#testing)
- [Inputs](#inputs)
- [Outputs](#outputs)

## Key capabilities

- **Create or reference a fabric:** independently select ownership for one Global
  Network and one Core Network without deriving resource count from computed IDs.
- **Stable composition handle:** consume scalar IDs and ARNs, topology maps keyed
  by Region or segment, and the versioned `fabric_handle` contract.
- **Create-only base policy:** seed a new Core Network from Regions or an exact
  policy document, optionally protected by a reviewed SHA-256 digest.
- **Continuous policy deployment:** submit `2021.12` or `2025.11` documents with
  optional digest approval and configurable provider update timeout.
- **Explicit sharing:** create or reference a RAM share and manage Core Network,
  account, Organization, and organizational-unit associations under stable keys.
- **Provider-by-role composition:** keep fabric operations in their deployment
  Region and bind RAM operations to a commercial `us-east-1` provider.

## Cost warning

> [!WARNING]
> `terraform apply` can create Cloud WAN Core Network Edges, policy deployments,
> attachments, and RAM shares. Core Network Edge hours, attachment hours, data
> processing, inter-Region transfer, and connected VPC or security services can
> incur charges. Review [AWS Cloud WAN pricing](https://aws.amazon.com/cloud-wan/pricing/)
> and each example before applying. `terraform init` and `terraform validate`
> create no AWS resources.

## Quick start

```hcl
module "cloudwan" {
  source  = "aws-ia/cloudwan/aws"
  version = "~> 4.0"

  global_network = { description = "production-global-network" }
  core_network = {
    description = "production-core-network"
    base_policy = { regions = ["us-west-2", "eu-west-1"] }
  }

  tags = { Environment = "production" }
}
```

The `create` selector at each fabric boundary must be known during planning;
resource IDs may be computed. Creating a Global Network while referencing a Core
Network is invalid because the referenced Core Network must already belong to an
existing Global Network.

## Documentation

- [Fabric ownership and references](docs/fabric.md) — create-or-reference modes,
  valid combinations, create-only base policy, topology outputs, and
  `fabric_handle`.
- [Policy deployment](docs/policy-deployment.md) — document-to-deployed flow,
  approval digests, timeouts, LIVE/LATEST verification, and recovery.
- [Core Network sharing](docs/sharing.md) — RAM Region and partition constraints,
  principal forms, stable association keys, and attachment-accepter safety.
- [Composition patterns](docs/composition.md) — compact and separate-state
  layouts, providers by role, and the VPC v5 attachment boundary.
- [Testing and validation](docs/testing.md) — mock suite, example plan tests,
  generated documentation checks, and the first-hop mutation verifier.
- [Upgrade guide 4.0](UPGRADE-GUIDE-4.0.md) — non-destructive migration from v3,
  first-hop plan allowlisting, cross-state handoff, and rollback.

## Examples

| Example | What it demonstrates | Choose it when | External prerequisites and cost |
|---|---|---|---|
| [`basic`](examples/basic) | One created fabric and continuous policy deployment. | You need the smallest complete fabric-plus-policy composition. | Creates a Global Network, Core Network, one edge, and policy deployment. |
| [`reference_core_network`](examples/reference\_core\_network) | ID-only fabric reference with resolved topology outputs. | Another state owns the Global Network and Core Network. | Requires real related IDs for an AWS plan; creates no Network Manager resources. |
| [`core_network_share`](examples/core\_network\_share) | Core Network sharing through a role-named `aws.ram` provider. | Accounts or AWS Organizations principals need access to the Core Network. | RAM runs in commercial `us-east-1`; association acceptance depends on principal type and Organizations integration. |
| [`stack_compact`](examples/stack\_compact) | Fabric, policy, and optional sharing in one state. | One team owns the complete lifecycle and wants one plan. | Creates the selected fabric, policy, and optional RAM resources. |

Examples are ordinary Terraform configurations. Their native tests use mocked
providers and do not contact AWS; replace placeholder IDs, account numbers, and
principal ARNs before a real plan.

## Operational boundaries

- **Base policy versus deployed policy:** `core_network.base_policy` is consumed
  only when the Core Network is created. Use `modules/policy-deployment` for
  subsequent policy changes.
- **LIVE versus LATEST:** a successful policy resource operation is not evidence
  that the submitted document is LIVE. Verify the LIVE alias, expected digest,
  successful execution, and change events through the AWS API.
- **Reference mode:** referenced fabric and share resources retain their external
  lifecycle owner; this module resolves normalized outputs without adopting them.
- **Attachment accepters:** destroying
  `aws_networkmanager_attachment_accepter` calls `DeleteAttachment` and deletes
  the spoke-owned attachment. Transfer state with
  `removed { lifecycle { destroy = false } }`, adopt the same attachment ID in
  the destination, and verify ownership before retiring the old configuration.
- **Output stability:** scalar IDs and ARNs, topology maps, and
  `fabric_handle.schema_version = "cloudwan-fabric-handle/v1"` are stable public
  contracts. `core_network_state` is last-refresh state, not continuous health or
  policy deployment evidence.

## Testing

Mock-provider tests require Terraform `>= 1.7` and create no AWS resources.

```shell
terraform fmt -check -recursive
terraform init -backend=false
terraform validate -no-color
terraform test -no-color
./scripts/check-content.sh
```

Reusable modules require AWS provider `>= 6.59`. Executable root configurations
should commit their dependency lock file and apply an upper bound when their
provider upgrade policy requires one.

---

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.59 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.59 |
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
| [terraform_data.fabric_contract](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
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
| <a name="output_fabric_handle"></a> [fabric\_handle](#output\_fabric\_handle) | Versioned Global Network and Core Network handle for cross-module and cross-state composition. |
| <a name="output_global_network_arn"></a> [global\_network\_arn](#output\_global\_network\_arn) | Global Network ARN in create and reference modes. |
| <a name="output_global_network_id"></a> [global\_network\_id](#output\_global\_network\_id) | Global Network ID in create and reference modes. |
<!-- END_TF_DOCS -->