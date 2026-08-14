# Basic fabric and policy

This example creates one Global Network, one Core Network, and one continuous
policy deployment in the same state. Use it as the smallest complete
fabric-plus-policy composition.

## What this demonstrates

- A service-native policy document used for both Core Network creation and
  continuous policy deployment.
- A create-only base-policy boundary separate from subsequent policy lifecycle.
- A 60-minute provider update timeout for the policy attachment.
- Stable fabric IDs plus the exact policy-document SHA-256 output.

## Relevant configuration

The complete configuration is in [`main.tf`](./main.tf). The shared document and
policy-deployment boundary are the scenario-specific portion:

```hcl
core_network = {
  description = "basic-core-network"
  base_policy = {
    policy_document = local.policy_document
  }
}

module "policy" {
  source = "../../modules/policy-deployment"

  core_network_id = module.cloudwan.core_network_id
  policy_document = local.policy_document
  timeouts        = { update = "60m" }
}
```

## Prerequisites and cost

- Terraform `>= 1.7` and AWS provider `>= 6.59`.
- Credentials with Network Manager permissions for a real plan or apply.
- Applying creates a Global Network, Core Network Edge, and policy deployment;
  Cloud WAN edge, attachment, processing, and transfer charges can apply.

## Run

```shell
terraform init
terraform validate
terraform plan -out=tfplan
terraform output policy_document_sha256
```

After a real apply, verify the LIVE alias, document digest, execution state, and
change events using the [policy deployment guide](../../docs/policy-deployment.md).
A successful Terraform operation alone is not LIVE-policy evidence.
