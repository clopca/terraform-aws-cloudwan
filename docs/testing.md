# Testing and validation

The repository test path is plan-only and uses Terraform mock providers. It must
not run a real `terraform apply` against AWS.

## Local quality gate

Run the same checks required by CI:

```shell
terraform fmt -check -recursive
terraform init -backend=false -lockfile=readonly
terraform validate -no-color

for directory in modules/* examples/*; do
  terraform -chdir="$directory" init -backend=false -lockfile=readonly
  terraform -chdir="$directory" validate -no-color
done

terraform test -no-color
./scripts/check-content.sh
```

The root suite covers fabric ownership, computed inputs, create-only base policy,
policy approval and deployment, sharing, examples, and the v3-to-v4 first hop.
Mocked plan success proves Terraform expression, provider schema, module
contract, and assertion behavior. It does not prove resource existence, IAM,
service quotas, policy execution, attachment readiness, or dataplane routing.

## First-hop migration verifier

Run the verifier directly when changing migration documentation, moved blocks,
fixtures, or allowlist behavior:

```shell
python3 tests/verify_v3_to_v4_first_hop.py
```

The verifier:

1. applies a minimal v3-shaped state with `mock_provider`;
2. plans the real v4 root and public submodules against that in-memory state;
3. extracts the six-entry allowlist and checker from
   `UPGRADE-GUIDE-4.0.md`;
4. proves that the documented checker accepts the expected plan;
5. removes each allowlist entry in turn and requires rejection;
6. adds an unexpected action and requires rejection.

This mutation step prevents the migration test from passing merely because a
copied policy or fixture repeats the expected result. The verifier is chained
through `scripts/check-content.sh`, and CI runs that content guard before the
complete Terraform test suite.

## Example plan tests

Each example has a dedicated `run` block in `tests/examples.tftest.hcl`. Provider
resource and data-source outputs are mocked, so tests can plan placeholder IDs
and RAM associations without network access or AWS credentials.

A new example is complete only when it has:

- ordinary Terraform files that pass `fmt`, `init`, and `validate`;
- a README showing only the scenario-specific HCL;
- an explicit mocked plan run;
- assertions for the output or contract that distinguishes the scenario;
- a root example-table entry describing prerequisites and cost.

## Generated documentation guard

`scripts/check-content.sh` enforces:

- the root title, navigation, quick start, Registry source, and version;
- required thematic pages and scenario READMEs;
- absence of diagram and internal process vocabulary;
- valid local Markdown links;
- parseable HCL fences;
- exact README regeneration from `.header.md` through `terraform-docs`;
- the first-hop mutation verifier.

Run `terraform-docs .` after changing `.header.md`, variables, providers,
resources, modules, or outputs. Commit `.header.md` and the regenerated README in
the same change.

## Real-environment verification boundaries

A reviewed real deployment needs separate operational evidence:

- fabric IDs, ARNs, edge Regions, segments, and provider/account bindings;
- LIVE and LATEST policy versions, exact digest, execution state, and change
  events;
- RAM share and principal association state from the owner and consumer sides;
- attachment acceptance, route-table intent, and traffic verification for every
  connected VPC.

Keep those artifacts outside the source checkout. Do not add state files, saved
plans, credentials, account inventories, or captured API responses to this
repository.
