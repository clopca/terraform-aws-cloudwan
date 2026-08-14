# Cloud WAN policy 2025.11

This example renders a `2025.11` Cloud WAN policy with the official AWS provider
data source and deploys it through the policy submodule. Use it when routing
policies and service insertion must be represented in provider-validated HCL.

## What this demonstrates

- `aws_networkmanager_core_network_policy_document` with `version = "2025.11"`.
- An inbound routing policy that sets local preference for private prefixes.
- Attachment label mapping to a routing policy.
- Single-hop service insertion through an `inspection` network function group.
- Exact-byte digest approval of the rendered provider document.

## Relevant configuration

The complete configuration is in [`main.tf`](./main.tf). The new policy surfaces
are the differential portion:

```hcl
data "aws_networkmanager_core_network_policy_document" "routing_and_inspection" {
  version = "2025.11"

  network_function_groups {
    name                          = "inspection"
    require_attachment_acceptance = true
  }

  routing_policies {
    routing_policy_name      = "preferprivate"
    routing_policy_direction = "inbound"
    routing_policy_number    = 100

    routing_policy_rules {
      rule_number = 100
      rule_definition {
        match_conditions {
          type  = "prefix-in-cidr"
          value = "10.0.0.0/8"
        }
        action {
          type  = "set-local-preference"
          value = "200"
        }
      }
    }
  }

  segment_actions {
    action  = "send-via"
    mode    = "single-hop"
    segment = "application"
    when_sent_to { segments = ["sharedservices"] }
    via { network_function_groups = ["inspection"] }
  }
}
```

## Prerequisites and cost

- Terraform `>= 1.7` and an AWS provider release that exposes the `2025.11`
  policy blocks.
- Network function attachments tagged for the declared group before traffic is
  directed through the service-insertion action.
- Applying creates a fabric and deploys a policy; Cloud WAN edge, attachment,
  processing, service-insertion, and transfer charges can apply.

## Run

```shell
terraform init
terraform validate
terraform plan -out=tfplan
terraform output policy_version
terraform output policy_document_sha256
```

Provider rendering proves schema construction, not that network function
attachments are ready or that the document is LIVE. Verify attachment state,
routing-policy labels, LIVE digest, execution, and change events after apply.
