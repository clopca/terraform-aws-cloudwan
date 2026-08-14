#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "$*" >&2
  exit 1
}

grep -Fxq '# AWS Cloud WAN Module' "$repo_root/.header.md"
grep -Fxq '# AWS Cloud WAN Module' "$repo_root/README.md"
grep -Fxq '## Navigation' "$repo_root/.header.md"
grep -Fxq '## Key capabilities' "$repo_root/.header.md"
grep -Fxq '## Quick start' "$repo_root/.header.md"
grep -Fq 'source  = "aws-ia/cloudwan/aws"' "$repo_root/.header.md"
grep -Fq 'version = "~> 4.0"' "$repo_root/.header.md"

required_docs=(
  docs/fabric.md
  docs/policy-deployment.md
  docs/sharing.md
  docs/composition.md
  docs/testing.md
)
for relative in "${required_docs[@]}"; do
  [[ -f "$repo_root/$relative" ]] || fail "Missing thematic guide: $relative"
done
[[ "$(find "$repo_root/docs" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')" == "5" ]] || fail "docs/ must contain exactly five thematic Markdown guides"

required_examples=(
  basic
  reference_core_network
  core_network_share
  stack_compact
  policy_2025_11
  cross_account_sharing
)
for example in "${required_examples[@]}"; do
  for required in main.tf providers.tf outputs.tf README.md; do
    [[ -f "$repo_root/examples/$example/$required" ]] || fail "$example missing $required"
  done
  guide="$repo_root/examples/$example/README.md"
  grep -Fxq '## What this demonstrates' "$guide"
  grep -Fxq '## Relevant configuration' "$guide"
  grep -Fxq '## Prerequisites and cost' "$guide"
  grep -Fxq '## Run' "$guide"
  grep -Fq '(./main.tf)' "$guide"
done
[[ "$(find "$repo_root/examples" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" == "6" ]] || fail "examples/ must contain exactly six published scenarios"

if git -C "$repo_root" grep -niEI 'mermaid|analysis/|RFC|tanda|LDA' -- '*.md' ':(exclude)CHANGELOG.md'; then
  fail "Forbidden diagram or process vocabulary found in published Markdown"
fi

if git -C "$repo_root" grep -nEI '\b([0-9]+\.)?x\.x\b' -- '*.md'; then
  fail "Version placeholder (x.x) found in published Markdown; use a valid constraint or prose release name"
fi

python3 - "$repo_root" <<'PY'
from pathlib import Path
import re
import subprocess
import sys

root = Path(sys.argv[1])
tracked = subprocess.run(
    ["git", "-C", str(root), "ls-files", "*.md", ".header.md"],
    check=True,
    capture_output=True,
    text=True,
).stdout.splitlines()
failures = []
hcl_count = 0
for relative in tracked:
    path = root / relative
    if not path.is_file():
        continue
    text = path.read_text()
    for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", text):
        if re.match(r"^(?:https?://|mailto:|#)", target):
            continue
        clean = target.split("#", 1)[0].replace("\\_", "_")
        if clean and not (path.parent / clean).resolve().exists():
            failures.append(f"{relative}: broken link {target}")
    for index, block in enumerate(
        re.findall(r"^[ \t]*```hcl[ \t]*\n(.*?)^[ \t]*```[ \t]*$", text, re.M | re.S),
        1,
    ):
        hcl_count += 1
        result = subprocess.run(
            ["terraform", "fmt", "-"], input=block, text=True, capture_output=True
        )
        if result.returncode != 0:
            failures.append(f"{relative} HCL fence {index}: {result.stderr.strip()}")
if failures:
    raise SystemExit("\n".join(failures))
print(f"Validated Markdown links and HCL fences: {hcl_count}")
PY

scratch="$(mktemp -d "${TMPDIR:-/tmp}/cloudwan-docs-check.XXXXXX")"
trap 'rm -R -- "$scratch"' EXIT
cp "$repo_root/.header.md" "$repo_root/.terraform-docs.yaml" "$scratch/"
cp "$repo_root"/*.tf "$scratch/"
terraform-docs "$scratch" >/dev/null
cmp -s "$repo_root/README.md" "$scratch/README.md" || fail "README.md is not generated from .header.md and the current Terraform contract"

python3 "$repo_root/tests/verify_v3_to_v4_first_hop.py"

echo "Cloud WAN published content checks passed"
