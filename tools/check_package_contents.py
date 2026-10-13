#!/usr/bin/env python3
"""Ensure development-only files are excluded from the published archive."""
from pathlib import Path
import shutil
import subprocess
import sys
import zipfile


ROOT = Path(__file__).resolve().parents[1]
MOON = shutil.which("moon") or str(Path.home() / ".moon/bin/moon")
FORBIDDEN_PREFIXES = ("src/ci_probe/", "testdata/", "tools/")
FORBIDDEN_FILES = {"ready_to_pr.sh"}


def main():
    result = subprocess.run(
        [MOON, "package", "--list"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    output = result.stdout + result.stderr
    archive_line = next(
        (line for line in output.splitlines() if line.startswith("Package to ")),
        None,
    )
    if archive_line is None:
        raise SystemExit("moon package --list did not report the package archive")
    archive = Path(archive_line.removeprefix("Package to "))
    if not archive.is_file():
        raise SystemExit(f"package archive was not created: {archive}")

    with zipfile.ZipFile(archive) as package:
        names = set(package.namelist())
    listed = {
        line
        for line in output.splitlines()
        if line and not line.startswith(("Running ", "Finished.", "Check ", "Package to "))
    }
    if names != listed:
        raise SystemExit("moon package listing differs from the archive contents")

    forbidden = sorted(
        name
        for name in names
        if name in FORBIDDEN_FILES or name.startswith(FORBIDDEN_PREFIXES)
    )
    if forbidden:
        raise SystemExit("development files included in package:\n" + "\n".join(forbidden))
    print(f"Verified {len(names)} files in {archive.name}; development files are excluded.")


if __name__ == "__main__":
    main()
