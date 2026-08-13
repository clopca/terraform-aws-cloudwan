# Cloud WAN policy deployment

This module submits one service-native Cloud WAN policy document through
`aws_networkmanager_core_network_policy_attachment`. The AWS provider performs
Put, waits for generation, executes the change set, and waits for the Core
Network to return to `AVAILABLE`.

## Usage

```hcl
module "cloudwan_policy" {
  source  = "aws-ia/cloudwan/aws//modules/policy"
  version = "~> 4.0"

  core_network_id = module.cloudwan.core_network_id
  policy_document = file("${path.module}/policy.json")

  approval = {
    sha256      = var.approved_policy_sha256
    digest_kind = "policy_document_bytes"
  }

  timeouts = { update = "60m" }
}
```

The provider default and module default are 30 minutes. A 60-minute override is
recommended for global rollouts, but it is not an AWS completion guarantee. The
provider's LATEST-to-ready generation waiter remains fixed at five minutes and
is not extended by `timeouts.update`.

## LIVE is not observable from this resource

A successful Terraform apply does **not** prove that the submitted document is
LIVE. The provider reads LATEST, waits for `CoreNetwork.State=AVAILABLE`, and
does not verify the LIVE alias, `ChangeSetState=EXECUTION_SUCCEEDED`, or failed
change events. Consequently this module deliberately exposes
`core_network_state`, not `deployment_state`, and does not expose
`live_policy_version_id`.

### External verification runbook

Before apply, freeze other writers and call `GetCoreNetworkPolicy` for both
`Alias=LIVE` and `Alias=LATEST`. Record version IDs and change-set state; stop if
another execution or unreconciled LATEST version exists. Review the saved plan
and the approved document digest.

After apply:

1. Call `GetCoreNetworkPolicy` with `Alias=LIVE` and verify the exact expected
   digest.
2. Record the returned `PolicyVersionId` as deployment evidence.
3. Verify the executed policy reached `EXECUTION_SUCCEEDED`.
4. Call `GetCoreNetworkChangeEvents` and reject relevant `FAILED` events.
5. Preserve the API evidence with the saved Terraform plan.

### False convergence or timeout recovery

Treat a timeout after Execute as indeterminate; AWS does not cancel the remote
operation. Freeze every policy writer, inspect LIVE and LATEST plus version IDs,
change-set state, events, and Core Network state. If LATEST is `EXECUTING`, wait
rather than reapply. If it is `FAILED_GENERATION`, correct or abandon that
version through the AWS workflow; a no-diff Terraform apply does not reliably
retry it. Declare success only when LIVE has the expected digest, execution
succeeded, and no relevant failed event remains. Finally refresh state and
require a clean plan before the next rollout.
