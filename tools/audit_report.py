#!/usr/bin/env python3
"""Aggregate audit results into one Markdown report.

Reads every `*.json` written by `tools/run_audit.py` (and the optional
`mutation.json` of `tools/mutation_check.py`) below the given directory.

    python3 tools/audit_report.py _build/audit > audit-report.md
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from compiler_matrix import analyze  # noqa: E402


def main():
    root = Path(sys.argv[1] if len(sys.argv) > 1 else "_build/audit")
    runs = [json.loads(p.read_text()) for p in sorted(root.rglob("*.json")) if p.name != "mutation.json"]
    runs = [r for r in runs if "backend" in r]
    mutation_files = sorted(root.rglob("mutation.json"))
    lines = ["# luna-utils audit report", ""]
    seeds = sorted({r["seed"] for r in runs})
    lines.append(f"Seed: {', '.join(map(str, seeds)) or 'n/a'}. The seed regenerates the cases exactly "
                 "(`python3 tools/random_audit.py --seed N --count M --write`).")
    lines += ["", "## Backends", "", "| Backend | Mode | Cases | Unexpected mismatches | Test exit |", "| --- | --- | ---: | ---: | ---: |"]
    for r in runs:
        lines.append(f"| {r['backend']} | {r['mode']} | {r['cases']} | {r.get('unexpected', r['mismatch_count'])} | {r['exit_code']} |")
    families = sorted({f for r in runs for f in r["families"]})
    if families:
        lines += ["", "## Families", "", "| Family | Cases | Mismatches (all runs) |", "| --- | ---: | ---: |"]
        for f in families:
            cases = max(r["families"].get(f, {}).get("cases", 0) for r in runs)
            bad = sum(r["families"].get(f, {}).get("mismatches", 0) for r in runs)
            lines.append(f"| {f} | {cases} | {bad} |")
    bad_runs = [r for r in runs if r.get("unexpected", r["mismatch_count"])]
    known = [(r, k) for r in runs for k in r.get("known", []) if k["mismatches"]]
    if known:
        lines += ["", "## Known issues (excluded from the verdict)", "", "| Backend | Mode | Family | Mismatches | Issue |", "| --- | --- | --- | ---: | --- |"]
        for r, k in known:
            lines.append(f"| {r['backend']} | {r['mode']} | {k['family']} | {k['mismatches']} | {k['issue']} |")
    fixed = [(r, k) for r in runs for k in r.get("known", []) if not k["mismatches"]]
    for r, k in fixed:
        lines.append(f"\nKnown issue {k['issue']} no longer reproduces on {r['backend']} {r['mode']}; remove it from `tools/known_issues.json`.")
    if bad_runs:
        lines += ["", "## Mismatch samples", ""]
        for r in bad_runs:
            lines.append(f"### {r['backend']} {r['mode']}")
            lines += ["", "```", *r["samples"][:20], "```", ""]
    for p in mutation_files:
        lines += ["", "## Mutation check", "", "| Injected bug | Result |", "| --- | --- |"]
        for m in json.loads(p.read_text()):
            lines.append(f"| {m['mutation']} | {m['status']} |")
    matrix_files = sorted(str(p) for p in root.rglob("*.txt") if p.parent.name == "matrix")
    matrix = analyze(matrix_files) if matrix_files else None
    if matrix:
        lines += ["", "## Compiler matrix", "",
                  f"{matrix['cells']} cells from {len(matrix_files)} transcripts "
                  "(container invariance, debug against release, and across backends for integer, Bool and Char types).", ""]
        counts = {k: len(v) for k, v in matrix["findings"].items()}
        lines.append(f"Unexpected findings: {counts or 'none'}.")
        for issue, n in matrix["known"].items():
            lines.append(f"\nKnown issue hits (excluded from the verdict): {n} from {issue}")
        for kind, items in matrix["findings"].items():
            lines += ["", "```", *[json.dumps(i) for i in items[:20]], "```"]
    survivors = [m for p in mutation_files for m in json.loads(p.read_text()) if m["status"] in ("SURVIVED", "STALE")]
    ok = runs and not bad_runs and not survivors and not (matrix and matrix['findings'])
    lines += ["", f"**Verdict: {'PASS' if ok else 'FAIL'}**"]
    print("\n".join(lines))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
