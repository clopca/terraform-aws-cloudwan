#!/usr/bin/env python3
"""Verify the documented v3-to-v4 first-hop allowlist against a mock plan."""

from __future__ import annotations

import copy
import json
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
GUIDE = ROOT / "UPGRADE-GUIDE-4.0.md"
TEST_FILE = "tests/v3_to_v4_first_hop.tftest.hcl"
RUN_NAME = "plan_v4_first_hop"


def extract_fence(document: str, marker: str) -> str:
    begin = f"<!-- BEGIN {marker} -->"
    end = f"<!-- END {marker} -->"
    try:
        marked = document.split(begin, 1)[1].split(end, 1)[0]
        return marked.split("```", 2)[1].split("\n", 1)[1]
    except (IndexError, ValueError) as error:
        raise SystemExit(f"could not extract {marker} from {GUIDE}") from error


def run_checker(
    checker: pathlib.Path, plan: pathlib.Path, allowlist: pathlib.Path
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(checker), str(plan), str(allowlist)],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )


def main() -> None:
    test = subprocess.run(
        [
            "terraform",
            "test",
            f"-filter={TEST_FILE}",
            "-json",
            "-verbose",
            "-no-color",
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if test.returncode != 0:
        sys.stderr.write(test.stdout)
        sys.stderr.write(test.stderr)
        raise SystemExit("stateful mock first-hop test failed")

    plans = []
    for line in test.stdout.splitlines():
        event = json.loads(line)
        if event.get("@testrun") == RUN_NAME and "test_plan" in event:
            plans.append(event["test_plan"])
    if len(plans) != 1:
        raise SystemExit(f"expected one verbose plan for {RUN_NAME}, found {len(plans)}")
    plan = plans[0]

    guide = GUIDE.read_text()
    allowlist_text = extract_fence(guide, "V4 FIRST-HOP ALLOWLIST")
    checker_text = extract_fence(guide, "V4 PLAN ALLOWLIST CHECKER")
    allowlist_lines = [
        line
        for line in allowlist_text.splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    if len(allowlist_lines) != 6:
        raise SystemExit(
            f"the documented first-hop allowlist must contain 6 entries, found {len(allowlist_lines)}"
        )

    with tempfile.TemporaryDirectory(prefix="cloudwan-v4-first-hop-") as temporary:
        directory = pathlib.Path(temporary)
        plan_path = directory / "v4-first-hop.plan.json"
        allowlist_path = directory / "v4-first-hop.allowlist"
        checker_path = directory / "check-plan-allowlist.py"
        plan_path.write_text(json.dumps(plan))
        allowlist_path.write_text(allowlist_text)
        checker_path.write_text(checker_text)

        accepted = run_checker(checker_path, plan_path, allowlist_path)
        if accepted.returncode != 0:
            sys.stderr.write(accepted.stdout)
            sys.stderr.write(accepted.stderr)
            raise SystemExit("the documented checker rejected the mock first-hop plan")
        if "plan accepted: 6 exact non-no-op actions" not in accepted.stdout:
            raise SystemExit(f"unexpected checker result: {accepted.stdout.strip()}")

        for removed in allowlist_lines:
            mutation = "\n".join(
                line for line in allowlist_text.splitlines() if line != removed
            )
            allowlist_path.write_text(mutation + "\n")
            rejected = run_checker(checker_path, plan_path, allowlist_path)
            if rejected.returncode == 0:
                raise SystemExit(f"checker accepted allowlist without {removed}")

        allowlist_path.write_text(allowlist_text)
        extra_plan = copy.deepcopy(plan)
        extra_plan.setdefault("resource_changes", []).append(
            {
                "address": "terraform_data.unexpected_first_hop_action",
                "change": {"actions": ["create"]},
            }
        )
        plan_path.write_text(json.dumps(extra_plan))
        rejected = run_checker(checker_path, plan_path, allowlist_path)
        if rejected.returncode == 0:
            raise SystemExit("checker accepted an unexpected first-hop action")

    print(
        "verified stateful mock v3-like apply -> v4 plan: "
        "6 exact actions; all missing-entry and extra-action mutations rejected"
    )


if __name__ == "__main__":
    main()
