# Policy deployment

`modules/policy-deployment` submits one service-native Cloud WAN policy document
through `aws_networkmanager_core_network_policy_attachment`. It requests Put and
Execute, waits for provider readiness, and exposes document digests and the last
refreshed Core Network state.

## Document-to-deployed path

```hcl
module "cloudwan_policy" {
  source  = "aws-ia/cloudwan/aws//modules/policy-deployment"
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

The document must be valid JSON and use policy version `2021.12` or `2025.11`.
It must include at least one named edge location and one named segment. The
provider remains responsible for complete service-side policy validation.

A normal release sequence is:

1. Freeze every other writer for the Core Network.
2. Capture the current LIVE and LATEST versions and change-set state.
3. Produce and review a saved Terraform plan.
4. Compare the reviewed document with the selected approval digest.
5. Apply the exact saved plan.
6. Verify LIVE, execution state, and failed events through AWS read APIs.
7. Refresh Terraform state and require a clean plan before releasing the writer
   freeze.

## LIVE and LATEST are different evidence

The provider reads LATEST after submitting the document. A successful resource
operation does not prove that the desired bytes are available through the LIVE
alias, that execution reached `EXECUTION_SUCCEEDED`, or that no relevant change
event failed. For that reason the module does not expose a misleading
`live_policy_version_id` or deployment-success output.

Use read-only AWS CLI calls after credentials are configured in the caller's
terminal:

```shell
aws networkmanager get-core-network-policy \
  --core-network-id "$CORE_NETWORK_ID" \
  --alias LIVE \
  --profile "$AWS_PROFILE" \
  --output json

aws networkmanager get-core-network-policy \
  --core-network-id "$CORE_NETWORK_ID" \
  --alias LATEST \
  --profile "$AWS_PROFILE" \
  --output json

aws networkmanager get-core-network-change-events \
  --core-network-id "$CORE_NETWORK_ID" \
  --policy-version-id "$POLICY_VERSION_ID" \
  --profile "$AWS_PROFILE" \
  --output json
```

Record the LIVE policy version, exact document digest, change-set state, Core
Network state, and relevant change events with the saved plan.

## Approval digests

`approval.digest_kind` chooses what is compared:

| Value | Digest input | Use when |
|---|---|---|
| `policy_document_bytes` | Exact UTF-8 bytes supplied to the module | Byte identity, whitespace, and key order are part of the approved artifact. |
| `terraform_canonical_json` | `jsonencode(jsondecode(policy_document))` | JSON semantic structure is approved independently of formatting. |

A SHA-256 match establishes equality only. The release workflow remains
responsible for provenance, independent review, intended account and Core
Network, and saved-plan approval.

## Timeouts and indeterminate results

The provider default and module default update timeout are 30 minutes. A longer
value such as `60m` can accommodate global rollout latency, but it does not
extend every internal provider waiter and is not an AWS completion guarantee.

Treat a timeout after Execute as indeterminate:

1. Keep all policy writers frozen.
2. Read LIVE and LATEST, their version IDs, change-set states, Core Network state,
   and change events.
3. If LATEST is executing, wait instead of submitting another version.
4. If generation failed, correct or abandon that version through the AWS
   workflow; a no-diff Terraform apply may not retry it.
5. Declare success only when LIVE has the approved digest, execution succeeded,
   and no relevant failed event remains.
6. Refresh state and require a clean plan.

## Policy checklist

- Use the root base policy only during Core Network creation.
- Keep one policy writer active per Core Network.
- Review a saved plan and bind approval to an exact digest definition.
- Treat Terraform success as configuration evidence, not LIVE evidence.
- Preserve API evidence for LIVE, LATEST, execution, and change events.
- Investigate timeouts before retrying.
