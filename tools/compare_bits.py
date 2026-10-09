#!/usr/bin/env python3
"""Reject malformed, duplicate, missing and changed bit transcripts."""
import argparse
import difflib
from pathlib import Path
import re

RECORD = re.compile(r"LUNA_BITS [A-Za-z0-9_-]+ [0-9a-f]{16}")

def extract(text):
    records = [line for line in text.splitlines() if line.startswith("LUNA_BITS")]
    if not records or any(RECORD.fullmatch(line) is None for line in records):
        raise ValueError("missing or malformed bit records")
    ids = [line.split()[1] for line in records]
    if len(ids) != len(set(ids)):
        raise ValueError("duplicate bit record")
    return "\n".join(records) + "\n"

def compare(expected, actual, label):
    if expected != actual:
        raise ValueError("".join(difflib.unified_diff(expected.splitlines(True), actual.splitlines(True), fromfile="oracle", tofile=label)))

def main():
    parser = argparse.ArgumentParser(); parser.add_argument('transcripts', nargs='+', type=Path)
    parser.add_argument('--expected', type=Path, default=Path(__file__).resolve().parents[1]/'testdata/expected.bits')
    args = parser.parse_args(); expected = extract(args.expected.read_text())
    for path in args.transcripts:
        compare(expected, extract(path.read_text()), str(path))
    print(f"Verified {len(args.transcripts)} transcripts against {len(expected.splitlines())} oracle records")

if __name__ == '__main__': main()
