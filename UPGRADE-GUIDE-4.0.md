# Upgrade from Cloud WAN v3 to v4

Version 4 separates fabric, policy deployment, RAM sharing, and regional topology
ownership. A zero-destroy migration is possible only when refreshed state proves
the exact physical mapping. This guide is executable, but every address,
provider binding, key, ID, ARN, and digest must be replaced with values observed
in the caller's own backend.

## Migration matrix

| v3 surface | Status | v4 destination | Gate |
|---|---|---|---|
| Managed or referenced Global Network | **Migrable now** | Root `global_network` boundary | Preserve the existing ID and ownership mode. |
| Managed or referenced Core Network | **Migrable now** | Root `core_network` boundary | Preserve the existing ID, provider binding, tags, and exact create-only base-policy bytes. |
| Core Network policy attachment | **Migrable now** | `modules/policy-deployment` | Freeze writers; verify LIVE before and after; move or forget/import the same Core Network ID. |
| RAM resource share | **Migrable now** | `modules/core-network-share` | Use provider role alias `aws.ram`; preserve share ARN. |
| RAM resource/principal associations | **Migrable now** | Caller-keyed maps in `modules/core-network-share` | Derive every key and import ID from refreshed state; never infer a count index from HCL order. |
| `central_vpcs` and their attachments | **Blocked until the regional successor is published** | Future regional composition owner | Keep this cohort on v3; do not delete, re-create, or invent a temporary v4 address. |
| Network Firewall composition | **Blocked until its successor contract is published** | Future firewall composition owner | Keep on v3 with its current provider and state. |
| IGW route tables and associations owned by the v3 composition | **Blocked with the central-VPC cohort** | Future regional owner | Move only when the destination address and provider binding are released. |
| Calculation-only subnet CIDR helpers | **Blocked with their consumer** | Successor typed outputs | Remove only after the successor proves equivalent outputs. |

Do not start a v4 cutover for a state that contains a blocked cohort unless the
migration boundary has already isolated that cohort in a separate unchanged
state.

## Preconditions

- Terraform 1.7 or newer and AWS provider 6.59 or newer.
- The v3 configuration is converged from a normal full refresh plan; no
  `-target`, `-refresh=false`, or stale saved plan.
- Every Cloud WAN policy writer is frozen. Record LIVE and LATEST policy version
  IDs, exact digests, change-set state, and failed change events.
- The authoritative backend is locked for the complete handoff window.
- State backups and plan evidence are stored outside the working directory.
- Any plan action containing `delete` is a hard stop, including
  `delete,create` replacements.

## 1. Capture the authoritative baseline

Run these commands from the **old v3 root** before changing configuration:

```shell
set -eu
mkdir -p migration-evidence
terraform version > migration-evidence/terraform-version.txt
terraform providers > migration-evidence/providers.txt
terraform state pull > migration-evidence/old-state.before.tfstate
terraform state list > migration-evidence/old-state.addresses.txt
terraform plan -out=migration-evidence/v3-converged.tfplan
terraform show -json migration-evidence/v3-converged.tfplan \
  > migration-evidence/v3-converged.plan.json
```

The converged plan must contain no resource changes. Record the physical
identity and provider binding for each migrable address:

```shell
while IFS= read -r address; do
  printf '\n===== %s =====\n' "$address"
  terraform state show -no-color "$address"
done < migration-evidence/old-state.addresses.txt \
  > migration-evidence/old-state.objects.txt
```

At minimum, reconcile Global Network ID/ARN, Core Network ID/ARN, share ARN,
resource ARN, every principal, description, tags, and provider configuration.

## 2. Extract and verify the exact v3 base-policy bytes

Set the exact Core Network state address. Managed v3 roots normally use the
address below; confirm it with `terraform state list` rather than assuming it:

```shell
export CORE_ADDRESS='module.cloudwan.aws_networkmanager_core_network.core_network[0]'
terraform show -json migration-evidence/old-state.before.tfstate \
  > migration-evidence/old-state.values.json
```

The following script writes the state string as UTF-8 **without adding a
newline**, preserving the bytes Terraform held:

```shell
python3 - "$CORE_ADDRESS" \
  migration-evidence/old-state.values.json \
  migration-evidence/base-policy.v3.json <<'PY'
import json
import pathlib
import sys

address, source, destination = sys.argv[1:]
document = json.loads(pathlib.Path(source).read_text())


def modules(module):
    yield module
    for child in module.get("child_modules", []):
        yield from modules(child)

matches = [
    resource
    for module in modules(document["values"]["root_module"])
    for resource in module.get("resources", [])
    if resource.get("address") == address
]
if len(matches) != 1:
    raise SystemExit(f"expected one resource at {address}, found {len(matches)}")
value = matches[0]["values"].get("base_policy_document")
if not isinstance(value, str) or not value:
    raise SystemExit("state does not contain a non-empty base_policy_document; inspect base_policy_regions instead")
pathlib.Path(destination).write_bytes(value.encode("utf-8"))
PY

python3 -m json.tool migration-evidence/base-policy.v3.json >/dev/null
shasum -a 256 migration-evidence/base-policy.v3.json \
  | tee migration-evidence/base-policy.v3.sha256
wc -c migration-evidence/base-policy.v3.json \
  | tee migration-evidence/base-policy.v3.bytes
```

Compare the digest and byte count with the version-controlled v3 source. If v3
used `base_policy_regions`, export the exact state set instead and use the
`regions` branch in the first-hop HCL. Do not convert between document and
regions during migration. The first v4 plan must receive the captured bytes and
the recorded SHA-256 through `approved_sha256`.

## 3. Write the complete v4 first-hop configuration

The following is a complete same-state first hop for a managed fabric, one policy
writer, and one RAM share. Replace values with baseline evidence; keep blocked
regional cohorts in their unchanged v3 state.

```hcl
terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.59"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

provider "aws" {
  alias  = "ram"
  region = "us-east-1"
}

variable "global_network_description" {
  type = string
}

variable "core_network_description" {
  type = string
}

variable "common_tags" {
  type    = map(string)
  default = {}
}

variable "approved_base_policy_sha256" {
  type = string
}

variable "resource_share_name" {
  type = string
}

variable "production_ou_arn" {
  type = string
}

locals {
  base_policy_document = file("${path.module}/migration-evidence/base-policy.v3.json")
  desired_policy       = file("${path.module}/policy.v3-live.json")
}

module "cloudwan" {
  source  = "aws-ia/cloudwan/aws"
  version = "~> 4.0"

  global_network = {
    create      = true
    description = var.global_network_description
    tags        = var.common_tags
  }

  core_network = {
    create      = true
    description = var.core_network_description
    base_policy = {
      policy_document = local.base_policy_document
      approved_sha256 = var.approved_base_policy_sha256
    }
    tags = var.common_tags
  }

  tags = var.common_tags
}

module "cloudwan_policy" {
  source  = "aws-ia/cloudwan/aws//modules/policy-deployment"
  version = "~> 4.0"

  core_network_id = module.cloudwan.core_network_id
  policy_document = local.desired_policy
  timeouts        = { update = "60m" }
}

module "cloudwan_share" {
  source  = "aws-ia/cloudwan/aws//modules/core-network-share"
  version = "~> 4.0"

  providers = { aws = aws.ram }

  resource_share = { name = var.resource_share_name }
  resources      = { core = module.cloudwan.core_network_arn }
  principals     = { production-ou = var.production_ou_arn }
}

moved {
  from = module.cloudwan.aws_networkmanager_core_network_policy_attachment.policy_attachment[0]
  to   = module.cloudwan_policy.aws_networkmanager_core_network_policy_attachment.this
}

moved {
  from = module.cloudwan.aws_ram_resource_share.resource_share[0]
  to   = module.cloudwan_share.aws_ram_resource_share.this[0]
}

moved {
  from = module.cloudwan.aws_ram_resource_association.resource_association[0]
  to   = module.cloudwan_share.aws_ram_resource_association.this["core"]
}

# Generate one block per state-observed principal. The count index and value
# below are examples and must match the old state exactly.
moved {
  from = module.cloudwan.aws_ram_principal_association.principal_association[0]
  to   = module.cloudwan_share.aws_ram_principal_association.this["production-ou"]
}
```

The two root singleton addresses remain unchanged when the module call remains
`module.cloudwan`:

```text
module.cloudwan.aws_networkmanager_global_network.global_network[0]
module.cloudwan.aws_networkmanager_core_network.core_network[0]
```

Use reference mode only for resources that v3 already referenced. A deliberate
managed-to-reference handoff requires `removed { destroy = false }` before
changing `create` to `false`.

## 4. Build an exact address and identity catalog

| v3 address pattern | v4 owner/address pattern | Import ID when crossing states |
|---|---|---|
| `module.cloudwan.aws_networkmanager_core_network_policy_attachment.policy_attachment[0]` | `module.cloudwan_policy.aws_networkmanager_core_network_policy_attachment.this` | Core Network ID |
| `module.cloudwan.aws_ram_resource_share.resource_share[0]` | `module.cloudwan_share.aws_ram_resource_share.this[0]` | Share ARN |
| `module.cloudwan.aws_ram_resource_association.resource_association[0]` | `module.cloudwan_share.aws_ram_resource_association.this["core"]` | `<share-arn>,<resource-arn>` |
| `module.cloudwan.aws_ram_principal_association.principal_association[N]` | `module.cloudwan_share.aws_ram_principal_association.this["<caller-key>"]` | `<share-arn>,<principal>` |

There are no wildcard moves. For every principal, compare the old state's
`principal` value with the destination map value. A mismatch proposes replacement
of a ForceNew association and fails the migration.

## 5. Save plans and run the executable allowlist gate

Generate the first-hop plan and JSON:

```shell
terraform init -upgrade
terraform plan -out=migration-evidence/v4-first-hop.tfplan
terraform show -json migration-evidence/v4-first-hop.tfplan \
  > migration-evidence/v4-first-hop.plan.json
```

Create an exact allowlist. Each line is `address|effective-action`; allowed
actions are `create`, `update`, `forget`, or `import`. Do not allow `delete`.
Moved resources with `no-op` need no allowlist entry.

```text
module.cloudwan_policy.aws_networkmanager_core_network_policy_attachment.this|update
```

Save the following as `migration-evidence/check-plan-allowlist.py`:

```python
#!/usr/bin/env python3
import json
import pathlib
import sys

plan_path, allowlist_path = map(pathlib.Path, sys.argv[1:])
plan = json.loads(plan_path.read_text())
allowed = {}
for number, raw in enumerate(allowlist_path.read_text().splitlines(), 1):
    line = raw.strip()
    if not line or line.startswith("#"):
        continue
    try:
        address, action = line.split("|", 1)
    except ValueError as error:
        raise SystemExit(f"invalid allowlist line {number}: {line}") from error
    allowed[address] = action

errors = []
seen = set()
for resource in plan.get("resource_changes", []):
    address = resource["address"]
    change = resource.get("change", {})
    actions = change.get("actions", [])
    if "delete" in actions:
        errors.append(f"{address}: forbidden action sequence {actions}")
        continue
    if change.get("importing") is not None:
        effective = "import"
    elif actions in ([], ["no-op"]):
        continue
    else:
        effective = ",".join(actions)
    seen.add(address)
    if allowed.get(address) != effective:
        errors.append(
            f"{address}: observed {effective!r}, allowlist has {allowed.get(address)!r}"
        )

for address in sorted(set(allowed) - seen):
    errors.append(f"{address}: allowlisted change was not present")
if errors:
    raise SystemExit("plan rejected:\n" + "\n".join(f"- {item}" for item in errors))
print(f"plan accepted: {len(seen)} exact non-no-op actions")
```

Run it against every saved plan:

```shell
python3 migration-evidence/check-plan-allowlist.py \
  migration-evidence/v4-first-hop.plan.json \
  migration-evidence/v4-first-hop.allowlist
```

Also compare before/after IDs, ARNs, provider bindings, tags, principals,
base-policy digest, and LIVE policy digest. Preserve the binary plan, JSON,
allowlist, state backups, identity manifest, and API evidence.

## 6. Same-state cutover

Only after the allowlist gate and human review pass:

1. Reconfirm the policy-writer freeze and backend lock.
2. Re-read the saved plan SHA-256 and ensure it is the reviewed artifact.
3. Apply that exact saved plan: `terraform apply migration-evidence/v4-first-hop.tfplan`.
4. Call `GetCoreNetworkPolicy(Alias=LIVE)` and verify the recorded digest,
   version, `EXECUTION_SUCCEEDED`, and no relevant failed event.
5. Run `terraform state pull`, `terraform state list`, and a new full plan.
6. Require unchanged physical IDs/ARNs and a clean plan before unfreezing writers.

## 7. Cross-state handoff: exact old-state/new-state order

A cross-state handoff is not transactional. Review both saved plans under one
operational lock. The **old state must forget first; the new state imports
second**. Reversing the order creates dual ownership.

Old-state non-destructive removal:

```hcl
removed {
  from = module.cloudwan.aws_networkmanager_core_network_policy_attachment.policy_attachment[0]
  lifecycle {
    destroy = false
  }
}
```

New-state adoption:

```hcl
import {
  to = module.cloudwan_policy.aws_networkmanager_core_network_policy_attachment.this
  id = var.core_network_id
}
```

Execute in this exact order:

1. Freeze all writers and acquire the operational lock spanning both backends.
2. Pull `old-state.before.tfstate` and `new-state.before.tfstate`; record serials.
3. Save `old-forget.tfplan` and `new-import.tfplan`; convert both to JSON.
4. Run the allowlist script on both plans. Old may contain only exact `forget`
   actions; new may contain only exact `import` actions and explicitly approved
   normalization updates. Neither may contain `delete`.
5. Apply **old state** `old-forget.tfplan`.
6. Verify through AWS read APIs that every physical object still exists with the
   same ID/ARN and that LIVE policy is unchanged.
7. Re-plan the new state to ensure its reviewed import assumptions are still
   current; regenerate and re-review if the saved plan is stale.
8. Apply **new state** `new-import.tfplan`.
9. Pull both states. Assert the old addresses are absent, new addresses are
   present, physical IDs match the baseline, and no object appears in both states.
10. Run clean full plans in old state first and new state second, then unfreeze
    writers.

Policy import reads LATEST, not authoritative LIVE. Compare LIVE externally
before step 5, after step 6, and after step 8.

## CAUTION: attachment accepter removal deletes the spoke attachment

Destroying `aws_networkmanager_attachment_accepter` invokes
`DeleteAttachment`; it deletes the attachment created in the spoke account. It
must not be used to revoke approval or to move state. Use a non-destructive
handoff with the exact address from your configuration:

```hcl
removed {
  from = module.attachment_accepters.aws_networkmanager_attachment_accepter.this["spoke"]
  lifecycle {
    destroy = false
  }
}
```

Plan the old-state forget and destination import together, then follow the exact
old-state/new-state order above. Verify the same attachment ID and owner account
from both sides before removing transitional blocks. Never use a normal destroy.

## 8. Rollback

### Before any state-changing apply

1. Abandon the migration plans.
2. Restore the v3 configuration and lock selection.
3. Run a full refresh plan and require it to be clean.
4. Verify LIVE policy and release the writer freeze.

### After old-state forget but before new-state import

1. Keep writers frozen and both backends locked.
2. Confirm through AWS read APIs that the physical resource still exists.
3. Remove the `removed` block, restore the old resource configuration, and import
   the object back to its exact old address. For example:

   ```shell
   terraform import \
     'module.cloudwan.aws_networkmanager_core_network_policy_attachment.policy_attachment[0]' \
     "$CORE_NETWORK_ID"
   ```

4. Import RAM objects with the IDs from the catalog: share ARN,
   `<share-arn>,<resource-arn>`, and `<share-arn>,<principal>`.
5. Pull old state, compare IDs/ARNs with `old-state.before.tfstate`, and require a
   clean old-state plan. Confirm the new state still owns none of these objects.
6. Verify LIVE policy, then release locks and writers.

### After new-state import

1. Keep writers frozen. Do not import the same object back into old state while
   new state still owns it.
2. Add destination `removed { destroy = false }` blocks and save a reviewed
   new-state forget plan.
3. Apply the **new-state forget first**, verify the physical objects still exist,
   then restore/import the old-state addresses from the catalog.
4. Pull both states and prove single ownership in old state, zero ownership in new
   state, unchanged IDs/ARNs, unchanged base-policy digest, and unchanged LIVE
   policy digest.
5. Require clean plans in new state first and old state second before unfreezing.

Use `terraform state push migration-evidence/old-state.before.tfstate` only as an
emergency backend recovery when no later state write occurred and the backend
serial/lineage have been independently verified. Prefer explicit imports because
they reconcile the live object rather than overwriting newer state metadata.

## Appendix: adopting from a custom wrapper

A custom wrapper may use singleton addresses without `[0]`, different module call
names, or separate provider bindings. It does not match the generic catalog. Build
the mapping from that wrapper's refreshed state and use caller-root moves such as:

```hcl
moved {
  from = module.custom_cloudwan.aws_networkmanager_global_network.this
  to   = module.cloudwan.aws_networkmanager_global_network.global_network[0]
}

moved {
  from = module.custom_cloudwan.aws_networkmanager_core_network.this
  to   = module.cloudwan.aws_networkmanager_core_network.core_network[0]
}
```

Move its policy singleton to `modules/policy-deployment`, or use the cross-state
forget/import sequence. A wrapper-specific catalog must enumerate every physical
resource, provider binding, count index, map key, and import ID from real state.
No external appendix or internal repository path is required: the authoritative
inputs are the refreshed backend, the wrapper's current HCL, this guide's
allowlist gate, and AWS read evidence.
