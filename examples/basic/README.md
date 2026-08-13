# Basic fabric and policy

Creates one Global Network, one Core Network with an explicit create-only base
policy, and one continuous policy deployment in the same Terraform state.
Terraform success must still be followed by the external LIVE verification
runbook in [`modules/policy-deployment`](../../modules/policy-deployment/README.md).
