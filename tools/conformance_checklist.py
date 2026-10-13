#!/usr/bin/env python3
"""Generate the conformance checklist and check the clause traceability tables.

The clause traceability tables of doc/manual/conformance/*.md are the source of
truth. This script condenses them into per-standard counts and a task list in
doc/manual/conformance/checklist.md, and checks that every `src/`, `testdata/`
and `tools/` path cited in a table exists.

    python3 tools/conformance_checklist.py          # check; exit 1 if stale
    python3 tools/conformance_checklist.py --write  # rewrite the block
"""

import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
PAGES = REPO_ROOT / "doc" / "manual" / "conformance"
TARGET = PAGES / "checklist.md"
START = "<!-- conformance-checklist-start -->"
END = "<!-- conformance-checklist-end -->"

STANDARDS = (
    ("IEEE 754-2019: float", "float.md"),
    ("Planned packages", "planned.md"),
)
STATES = ("conforming", "partial", "not implemented", "not applicable")


def classify(status: str) -> str:
    text = status.strip().lower()
    for state in STATES:
        if text.startswith(state):
            return state
    raise ValueError(f"unknown status: {status!r}")


def split_row(line: str) -> list[str]:
    return [cell.strip() for cell in re.split(r"(?<!\\)\|", line.strip().strip("|"))]


def clause_rows(page: Path) -> list[tuple[str, str, str, str]]:
    """Return (clause, level, evidence, status) of every row of the traceability table."""
    lines = page.read_text(encoding="utf-8").split("\n")
    rows = []
    in_section = False
    index = 0
    while index < len(lines):
        line = lines[index]
        if line.startswith("## "):
            in_section = line[3:].strip() == "Clause traceability"
        if in_section and line.startswith("|") and index + 1 < len(lines) and set(lines[index + 1]) <= set("| -"):
            index += 2
            while index < len(lines) and lines[index].startswith("|"):
                cells = split_row(lines[index])
                rows.append((cells[0], cells[1].split()[0], cells[3], cells[-1]))
                index += 1
            continue
        index += 1
    return rows


def missing_paths() -> list[str]:
    missing = []
    for _, name in STANDARDS:
        for clause, _, evidence, _ in clause_rows(PAGES / name):
            for path in re.findall(r"`((?:src|testdata|tools)/[^`\s]+)`", evidence):
                if not (REPO_ROOT / path).exists():
                    missing.append(f"{name}: {clause}: {path}")
    return missing


def build() -> str:
    counts = []
    blocks = []
    for title, name in STANDARDS:
        rows = clause_rows(PAGES / name)
        if not rows:
            raise SystemExit(f"no clause traceability table in {name}")
        tally = {state: 0 for state in STATES}
        tally["required gaps"] = 0
        tally["other gaps"] = 0
        items = []
        for clause, level, _, status in rows:
            state = classify(status)
            tally[state] += 1
            if state in ("partial", "not implemented"):
                tally["required gaps" if level == "required" else "other gaps"] += 1
            mark = "x" if state == "conforming" else " "
            suffix = "" if state == "conforming" else f" ({state})"
            items.append(f"- [{mark}] {clause} [{level}]{suffix}")
        counts.append((title, len(rows), tally))
        blocks.append((title, items))
    out = [
        "| Standard | Rows | Conforming | Partial | Not implemented | Not applicable | Required gaps | Recommended or optional gaps |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for title, total, tally in counts:
        out.append(
            f"| {title} | {total} | {tally['conforming']} | {tally['partial']} | {tally['not implemented']} | "
            f"{tally['not applicable']} | {tally['required gaps']} | {tally['other gaps']} |"
        )
    for title, items in blocks:
        out += ["", f"**{title}**", ""] + items
    return "\n".join(out)


def main(argv: list[str]) -> int:
    problems = missing_paths()
    if problems:
        print("conformance tables cite paths that do not exist:", *problems, sep="\n  ", file=sys.stderr)
        return 1
    text = TARGET.read_text(encoding="utf-8")
    if START not in text or END not in text:
        print(f"{TARGET}: checklist markers are missing", file=sys.stderr)
        return 2
    head, rest = text.split(START, 1)
    _, tail = rest.split(END, 1)
    fresh = f"{head}{START}\n{build()}\n{END}{tail}"
    if "--write" in argv:
        TARGET.write_text(fresh, encoding="utf-8")
        return 0
    if fresh != text:
        print("conformance/checklist.md is stale; run python3 tools/conformance_checklist.py --write", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
