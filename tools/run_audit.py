#!/usr/bin/env python3
"""Run the randomized audit on one backend in debug and release mode.

Writes `_build/audit/<backend>-<mode>.txt` (raw transcript) and
`_build/audit/<backend>-<mode>.json` (parsed summary). Exit status is non-zero
when any mode has a mismatch or the test run fails.

    python3 tools/run_audit.py js --seed 20261013 --count 5000
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from random_audit import report  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]


def known_issues(backend, mode):
    path = ROOT / "tools/known_issues.json"
    entries = json.loads(path.read_text()) if path.exists() else []
    return [e for e in entries if e["backend"] == backend and e["mode"] == mode]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("backend", choices=["wasm", "wasm-gc", "js", "native"])
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--count", type=int, default=400)
    parser.add_argument("--compiler")
    args = parser.parse_args()
    out = ROOT / "_build/audit"
    out.mkdir(parents=True, exist_ok=True)
    subprocess.run([sys.executable, "tools/random_audit.py", "--seed", str(args.seed), "--count", str(args.count), "--write"],
                   cwd=ROOT, check=True)
    failed = False
    for mode in ("debug", "release"):
        command = ["moon", "test", "--target", args.backend, "-p", "Luna-Flow/luna-utils/ci_probe",
                   "--no-parallelize", "--target-dir", str(ROOT / f"_build/audit-{args.backend}-{mode}")]
        if mode == "release":
            command.append("--release")
        result = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (out / f"{args.backend}-{mode}.txt").write_text(result.stdout)
        summary = report(result.stdout, args.seed)
        known = known_issues(args.backend, mode)
        known_families = {e["family"] for e in known}
        known_mismatches = sum(v["mismatches"] for f, v in summary["families"].items() if f in known_families)
        unexpected = summary["mismatch_count"] - known_mismatches
        totals = re.search(r"Total tests: (\d+), passed: (\d+), failed: (\d+)", result.stdout)
        failed_tests = int(totals.group(3)) if totals else None
        # With known mismatches the verdict test is expected to fail, and only that one.
        expected_failures = 1 if known_mismatches else 0
        summary.update(backend=args.backend, mode=mode, exit_code=result.returncode, unexpected=unexpected,
                       known=[dict(e, mismatches=summary["families"].get(e["family"], {}).get("mismatches", 0)) for e in known])
        (out / f"{args.backend}-{mode}.json").write_text(json.dumps(summary, indent=1))
        print(f"{args.backend} {mode}: {summary['cases']} cases, {unexpected} unexpected mismatches, "
              f"{known_mismatches} known, exit {result.returncode}")
        failed |= unexpected != 0 or summary["cases"] == 0 or failed_tests is None or failed_tests != expected_failures
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
