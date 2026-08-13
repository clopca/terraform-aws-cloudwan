# v3-to-v4 first-hop fixture

This fixture applies a minimal v3-like state shape with mocked AWS providers,
then plans the real v4 root and submodules against the same in-memory Terraform
test state. The companion `tests/verify_v3_to_v4_first_hop.py` extracts the
`plan_v4_first_hop` plan JSON, the first-hop allowlist, and its checker directly
from `UPGRADE-GUIDE-4.0.md`. It proves that all six expected actions are present,
that each allowlist entry is necessary, and that an extra action is rejected.

This is the closest hermetic representation of the first hop rather than an
apply of the complete published v3.4.1 root. The v3 root unconditionally declares
remote VPC and Network Firewall modules even when their `for_each` collections
are empty, so Terraform must download those blocked-cohort modules during init.
The fixture instead reproduces the exact migrable v3 resource addresses and AWS
provider schemas used by the guide. It does not claim to test the blocked
regional cohorts or real AWS behavior. Every AWS operation is handled by
`mock_provider`; no acceptance apply is performed.

Run the complete regression with:

```shell
python3 tests/verify_v3_to_v4_first_hop.py
```
