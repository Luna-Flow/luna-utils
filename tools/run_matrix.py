#!/usr/bin/env python3
"""Run the compiler matrix on one backend in debug and release mode.

Writes `_build/matrix/<backend>-<mode>.txt` and analyzes both transcripts for
container invariance and debug/release agreement. Cross-backend comparison is
done by `tools/audit_report.py` over the transcripts of all backends.

    python3 tools/run_matrix.py js
"""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from compiler_matrix import analyze  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]


def main():
    backend = sys.argv[1]
    out = ROOT / "_build/matrix"
    out.mkdir(parents=True, exist_ok=True)
    subprocess.run([sys.executable, "tools/compiler_matrix.py", "--write"], cwd=ROOT, check=True)
    paths = []
    for mode in ("debug", "release"):
        command = ["moon", "test", "--target", backend, "-p", "Luna-Flow/luna-utils/ci_probe", "--no-parallelize",
                   "--target-dir", str(ROOT / f"_build/matrix-{backend}-{mode}")]
        if mode == "release":
            command.append("--release")
        result = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        path = out / f"{backend}-{mode}.txt"
        path.write_text("".join(line + "\n" for line in result.stdout.splitlines() if line.startswith("CELL ")))
        # Other generated tests share the package; only a failure of the matrix itself counts here.
        if any("compiler_matrix_wbtest" in line and "failed" in line for line in result.stdout.splitlines()) \
                or not any(line.startswith("CELL ") for line in result.stdout.splitlines()):
            print(f"{backend} {mode}: the matrix did not run to completion (exit {result.returncode})")
            return 1
        paths.append(str(path))
    result = analyze(paths)
    counts = {k: len(v) for k, v in result["findings"].items()}
    print(f"{backend}: {result['cells']} cells, findings {counts or 'none'}, known hits {result['known'] or 'none'}")
    for kind, items in result["findings"].items():
        for item in items[:10]:
            print(" ", kind, item)
    return 1 if result["findings"] else 0


if __name__ == "__main__":
    sys.exit(main())
