#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "$*" >&2
  exit 1
}

grep -Fxq '# AWS Cloud WAN Terraform module' "$repo_root/.header.md"
grep -Fxq '# AWS Cloud WAN Terraform module' "$repo_root/README.md"
grep -Fq 'source  = "aws-ia/cloudwan/aws"' "$repo_root/.header.md"
grep -Fq 'version = "~> 4.0"' "$repo_root/.header.md"

if git -C "$repo_root" grep -niEI 'mermaid|analysis/|RFC|tanda|LDA' -- '*.md' ':(exclude)CHANGELOG.md'; then
  fail "Forbidden diagram or process vocabulary found in published Markdown"
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

python3 "$repo_root/tests/verify_v3_to_v4_first_hop.py"

echo "Cloud WAN published content checks passed"
