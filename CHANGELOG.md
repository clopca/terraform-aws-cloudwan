# Changelog

All notable changes to this module are documented in this file. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.0.0-alpha] - 2026-08-14

### Added

- Explicit create-or-reference contracts for one Global Network and one Core
  Network, including relationship validation for referenced fabrics.
- A versioned `fabric_handle` plus stable IDs, ARNs, Core Network state, edges by
  Region, and segments by name.
- Create-only base policy support from Regions or exact JSON, with optional
  SHA-256 approval of document bytes.
- `modules/policy-deployment` for `2021.12` and `2025.11` policy documents,
  byte or canonical-JSON approval digests, and configurable update timeouts.
- `modules/core-network-share` for create-or-reference RAM shares and stable-keyed
  Core Network, account, Organization, and organizational-unit associations.
- A non-destructive v3-to-v4 upgrade guide with saved-plan allowlisting,
  cross-state ownership transfer, rollback, and attachment-accepter safeguards.
- Five thematic guides covering fabric ownership, policy deployment, sharing,
  composition, and validation.
- Six mock-plannable examples, including provider-rendered `2025.11` routing
  policies with service insertion and AWS Organizations sharing.
- Terraform mock-provider coverage for fabric, policy, sharing, migration, and
  every published example, plus a mutation-tested first-hop verifier.
- CI gates for formatting, root/submodule/example initialization and validation,
  the complete Terraform test suite, generated documentation, HCL fences, links,
  and public-content structure.

### Changed

- The root interface is reduced to the fabric boundary; policy deployment and
  RAM sharing are explicit public submodules with separate ownership and provider
  roles.
- Resource cardinality is controlled by plan-known booleans rather than IDs, so
  computed identifiers can cross module boundaries safely.
- Ongoing policy changes use the policy-deployment submodule instead of mutating
  create-only Core Network base-policy attributes.
- RAM sharing uses an explicit commercial `us-east-1` provider and rejects
  unsupported partitions or Regions.
- Public documentation is organized as a concise Registry landing page,
  task-focused guides, and scenario READMEs containing differential HCL.

### Removed

- Root ownership of regional VPC, attachment, firewall, and route composition;
  VPC attachment topology composes with `aws-ia/vpc/aws` v5.
- Implicit policy and RAM lifecycle coupled to the root fabric resource.
- Provider-shaped resource-object outputs in favor of stable scalar and keyed
  composition contracts.

[4.0.0-alpha]: https://github.com/aws-ia/terraform-aws-cloudwan/compare/v3.4.1...v4.0.0-alpha
