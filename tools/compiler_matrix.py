#!/usr/bin/env python3
"""Compiler/backend consistency matrix for the numeric types Luna-Flow uses.

No expected values are computed. The matrix relies on two relations that any
correct compiler satisfies:

* container invariance: an operation applied to a value gives the same result
  whether the value arrives directly, inside an `Option`, an array element,
  a tuple, a struct field, an enum payload, a closure capture, a generic call,
  a mutable local, or as a compile-time constant;
* mode and backend invariance: debug and release builds, and every backend,
  print the same results for the integer, `Bool` and `Char` types. `Float` and
  `Double` are compared across containers and across debug and release only,
  because their cross-backend differences follow each backend's own float
  implementation by design.

The census behind the type, container and operation lists is in
`tools/usage_census.py`.

    python3 tools/compiler_matrix.py --write
    python3 tools/compiler_matrix.py --analyze OUT1.txt [OUT2.txt ...]
"""

import argparse
import json
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / "src/ci_probe/compiler_matrix_wbtest.mbt"

CONVERSIONS = {
    "Int": [("to_uint", "x.reinterpret_as_uint()"), ("to_int64", "x.to_int64()"), ("to_uint64", "x.to_uint64()")],
    "UInt": [("to_int", "x.reinterpret_as_int()"), ("to_int64", "x.to_int64()"), ("to_uint64", "x.to_uint64()")],
    "Int64": [("to_int", "x.to_int()"), ("to_uint64", "x.reinterpret_as_uint64()")],
    "UInt64": [("to_int", "x.to_int()"), ("to_uint", "x.to_uint()"), ("to_int64", "x.reinterpret_as_int64()")],
}
INT_OPS = [
    ("to_double_bits", "x.to_double().reinterpret_as_uint64()"),
    ("shr1", "x >> 1"), ("shr7", "x >> 7"), ("shl1", "x << 1"), ("shl5", "x << 5"),
    ("add1", "x + SUFFIX1"), ("sub7", "x - SUFFIX7"), ("mul3", "x * SUFFIX3"),
    ("div3", "x / SUFFIX3"), ("rem7", "x % SUFFIX7"),
    ("and", "x & MASK"), ("or", "x | MASK"), ("xor", "x ^ MASK"),
    ("gt5", "(x > SUFFIX5).to_int()"), ("lt5", "(x < SUFFIX5).to_int()"), ("eq", "(x == x).to_int()"),
    ("clz", "x.clz()"), ("ctz", "x.ctz()"), ("popcnt", "x.popcnt()"),
    ("to_string", "x.to_string().length()"), ("hex", "x.to_string(radix=16)"),
]

TYPES = {
    "Int": dict(suffix="", mask="0x0f0f0f0f", cross=True,
                values=["0", "1", "-1", "2", "127", "128", "255", "256", "65535", "65536", "0x40000000",
                        "2147483647", "(-2147483647)", "(-2147483647 - 1)"], ops=INT_OPS),
    "UInt": dict(suffix="U", mask="0x0f0f0f0fU", cross=True,
                 values=["0U", "1U", "2U", "0x7fU", "0x80U", "0xffU", "0xffffU", "0x10000U", "0x7fffffffU",
                         "0x80000000U", "0x80000001U", "0xc0000000U", "0xfffffffeU", "0xffffffffU"], ops=INT_OPS),
    "Int64": dict(suffix="L", mask="0x0f0f0f0f0f0f0f0fL", cross=True,
                  values=["0L", "1L", "-1L", "2147483647L", "2147483648L", "4294967295L", "4294967296L",
                          "0x7fffffffffffffffL", "(-0x7fffffffffffffffL)", "(-0x7fffffffffffffffL - 1L)", "0x4000000000000000L"],
                  ops=INT_OPS),
    "UInt64": dict(suffix="UL", mask="0x0f0f0f0f0f0f0f0fUL", cross=True,
                   values=["0UL", "1UL", "2UL", "0xffffffffUL", "0x100000000UL", "0x7fffffffffffffffUL",
                           "0x8000000000000000UL", "0x8000000000000001UL", "0xc000000000000000UL",
                           "0xfffffffffffffffeUL", "0xffffffffffffffffUL"], ops=INT_OPS),
    "UInt16": dict(suffix="", mask="0x0f0f", cross=True,
                   values=["0", "1", "2", "0x7f", "0x80", "0xff", "0x100", "0x7fff", "0x8000", "0x8001", "0xfffe", "0xffff"],
                   ops=[("to_int", "x.to_int()"), ("to_uint", "x.to_uint()"), ("to_uint64", "x.to_uint64()"),
                        ("to_int64", "x.to_int().to_int64()"), ("to_string", "x.to_string()"),
                        ("add1", "(x + 1).to_int()"), ("shr1", "(x >> 1).to_int()"), ("shl1", "(x << 1).to_int()"),
                        ("gt5", "(x > 5).to_int()"), ("eq", "(x == x).to_int()")], cast="to_uint16"),
    "Double": dict(suffix=".0", cross=False,
                   values=["0.0", "(-0.0)", "1.0", "(-1.0)", "0.5", "2.5", "10000000000.0", "4294967296.0", "9007199254740993.0",
                           "(0x7fefffffffffffffUL).reinterpret_as_double()", "(1UL).reinterpret_as_double()",
                           "(0x0010000000000000UL).reinterpret_as_double()"],
                   ops=[("bits", "x.reinterpret_as_uint64()"), ("add1", "(x + 1.0).reinterpret_as_uint64()"),
                        ("mul3", "(x * 3.0).reinterpret_as_uint64()"), ("div3", "(x / 3.0).reinterpret_as_uint64()"),
                        ("neg", "(-x).reinterpret_as_uint64()"), ("gt1", "(x > 1.0).to_int()"), ("eq", "(x == x).to_int()"),
                        ("abs", "x.abs().reinterpret_as_uint64()")]),
    "Float": dict(suffix="", cross=False,
                  values=["(0.0 : Float)", "(-0.0 : Float)", "(1.0 : Float)", "(-1.0 : Float)", "(0.5 : Float)", "(2.5 : Float)",
                          "Float::from_double(16777217.0)", "Float::reinterpret_from_uint(0x7f7fffffU)",
                          "Float::reinterpret_from_uint(1U)", "Float::reinterpret_from_uint(0x00800000U)"],
                  ops=[("bits", "x.reinterpret_as_uint()"), ("add1", "(x + (1.0 : Float)).reinterpret_as_uint()"),
                       ("mul3", "(x * (3.0 : Float)).reinterpret_as_uint()"), ("neg", "(-x).reinterpret_as_uint()"),
                       ("gt1", "(x > (1.0 : Float)).to_int()"), ("eq", "(x == x).to_int()")]),
    "Bool": dict(suffix="", cross=True, values=["false", "true"],
                 ops=[("to_int", "x.to_int()"), ("not", "(!x).to_int()"), ("and", "(x && true).to_int()"),
                      ("or", "(x || false).to_int()"), ("to_string", "x.to_string()")]),
    "Char": dict(suffix="", cross=True, values=["'a'", "'\\u{0}'", "'\\u{7f}'", "'\\u{80}'", "'\\u{ff}'", "'\\u{ffff}'", "'\\u{10000}'", "'\\u{10ffff}'"],
                 ops=[("to_int", "x.to_int()"), ("gt", "(x > 'b').to_int()"), ("eq", "(x == x).to_int()"),
                      ("to_string", "x.to_string().length()")]),
}


def ops_for(t):
    spec = TYPES[t]
    out = []
    for name, expr in CONVERSIONS.get(t, []) + spec["ops"]:
        expr = expr.replace("SUFFIX1", "1" + spec.get("suffix", "")).replace("SUFFIX3", "3" + spec.get("suffix", "")) \
            .replace("SUFFIX5", "5" + spec.get("suffix", "")).replace("SUFFIX7", "7" + spec.get("suffix", "")) \
            .replace("MASK", spec.get("mask", "0"))
        out.append((name, expr))
    return out


def body(t, cont, indent):
    lines = []
    for name, expr in ops_for(t):
        lines.append(f'{indent}emit("{cont}", "{t}", vi, "{name}", ({expr}).to_string())')
    return "\n".join(lines)


def emit_module():
    out = ["// Generated by tools/compiler_matrix.py; do not edit.",
           "///|", "fn emit(c : String, t : String, vi : Int, op : String, r : String) -> Unit {",
           '  println("CELL " + c + " " + t + " " + vi.to_string() + " " + op + " " + r)', "}", "",
           "///|", "fn[X] pass(x : X) -> X { x }", "",
           "///|", "fn[X] apply(x : X, f : (X) -> Unit) -> Unit { f(x) }", ""]
    for t, spec in TYPES.items():
        vals = [f"({v}).to_uint16()" if t == "UInt16" else v for v in spec["values"]]
        out += ["///|", f"struct S{t} {{ v : {t} }}", "", "///|", f"enum E{t} {{\n  A{t}({t})\n  B{t}\n}}", ""]
        out += ["///|", f"fn m_{t}_direct(x : {t}, vi : Int) -> Unit {{", body(t, "direct", "  "), "}", ""]
        out += ["///|", f"fn m_{t}_option(o : {t}?, vi : Int) -> Unit {{", "  match o {", "    Some(x) => {", body(t, "option", "      "),
                "    }", f'    None => emit("option", "{t}", vi, "none", "none")', "  }", "}", ""]
        out += ["///|", f"fn m_{t}_array_get(a : Array[{t}], vi : Int) -> Unit {{", "  match a.get(0) {", "    Some(x) => {", body(t, "array_get", "      "),
                "    }", f'    None => emit("array_get", "{t}", vi, "none", "none")', "  }", "}", ""]
        out += ["///|", f"fn m_{t}_array_index(a : Array[{t}], vi : Int) -> Unit {{", "  let x = a[0]", body(t, "array_index", "  "), "}", ""]
        out += ["///|", f"fn m_{t}_fixed(a : FixedArray[{t}], vi : Int) -> Unit {{", "  let x = a[0]", body(t, "fixed", "  "), "}", ""]
        out += ["///|", f"fn m_{t}_tuple(p : ({t}, Int), vi : Int) -> Unit {{", "  let (x, _) = p", body(t, "tuple", "  "), "}", ""]
        out += ["///|", f"fn m_{t}_struct(s : S{t}, vi : Int) -> Unit {{", "  let x = s.v", body(t, "struct", "  "), "}", ""]
        out += ["///|", f"fn m_{t}_enum(e : E{t}, vi : Int) -> Unit {{", "  match e {", f"    A{t}(x) => {{", body(t, "enum", "      "),
                "    }", f'    B{t} => emit("enum", "{t}", vi, "none", "none")', "  }", "}", ""]
        out += ["///|", f"fn m_{t}_closure(x : {t}, vi : Int) -> Unit {{", "  let f = () => {", body(t, "closure", "    "), "  }", "  f()", "}", ""]
        out += ["///|", f"fn m_{t}_generic(x0 : {t}, vi : Int) -> Unit {{", "  apply(pass(x0), x => {", body(t, "generic", "    "), "  })", "}", ""]
        out += ["///|", f"fn m_{t}_mutvar(x0 : {t}, n : Int, vi : Int) -> Unit {{", "  let mut x = x0", "  for _ in 0..<n {", "    x = pass(x)", "  }", body(t, "mutvar", "  "), "}", ""]
        # compile-time constants: the value is a literal in the same function
        out += ["///|", f"fn m_{t}_const() -> Unit {{"]
        for vi, lit in enumerate(vals):
            out += ["  {", f"    let vi = {vi}", f"    let x : {t} = {lit}", body(t, "const", "    "), "  }"]
        out += ["}", ""]
        out += ["///|", f'test "matrix {t}" {{', "  let zero = @env.args().length() >> 30",
                f"  let vals : Array[{t}] = [{', '.join(vals)}]", "  for vi in 0..<vals.length() {", "    let x = vals[vi]",
                f"    m_{t}_direct(x, vi)",
                f"    m_{t}_option(if zero > 100 {{ None }} else {{ Some(x) }}, vi)",
                f"    m_{t}_array_get([x], vi)", f"    m_{t}_array_index([x], vi)", f"    m_{t}_fixed(FixedArray::make(1, x), vi)",
                f"    m_{t}_tuple((x, zero), vi)", f"    m_{t}_struct({{ v: x }}, vi)",
                f"    m_{t}_enum(if zero > 100 {{ B{t} }} else {{ A{t}(x) }}, vi)",
                f"    m_{t}_closure(x, vi)", f"    m_{t}_generic(x, vi)", f"    m_{t}_mutvar(x, 1 + zero, vi)", "  }",
                f"  m_{t}_const()", "}", ""]
    return "\n".join(out)


def known_matrix_issues():
    path = ROOT / "tools/known_issues.json"
    entries = json.loads(path.read_text()) if path.exists() else []
    return [e["matrix"] | {"issue": e["issue"]} for e in entries if "matrix" in e]


def is_known(known, run, t, container):
    stem = Path(run).stem
    backend, mode = stem.rsplit("-", 1)
    for k in known:
        if k["backend"] == backend and k["mode"] == mode and t in k["types"] and container in k["containers"]:
            return k["issue"]
    return None


def analyze(paths):
    known = known_matrix_issues()
    runs = {}
    for path in paths:
        cells = {}
        for line in Path(path).read_text(errors="replace").splitlines():
            m = re.match(r"CELL (\S+) (\S+) (\d+) (\S+) (.*)$", line)
            if m:
                cells[(m.group(2), int(m.group(3)), m.group(4), m.group(1))] = m.group(5)
        runs[path] = cells
    findings = defaultdict(list)
    known_hits = defaultdict(int)
    total = 0
    for path, cells in runs.items():
        for (t, vi, op, cont), result in cells.items():
            total += 1
            direct = cells.get((t, vi, op, "direct"))
            if direct is not None and result != direct and cont not in ("none",):
                if result == "none":
                    continue
                issue = is_known(known, path, t, cont)
                if issue:
                    known_hits[issue] += 1
                    continue
                findings["container"].append(dict(run=path, type=t, value=vi, op=op, container=cont, got=result, direct=direct))
    names = list(runs)
    for i, a in enumerate(names):
        for b in names[i + 1:]:
            for key, ra in runs[a].items():
                t = key[0]
                rb = runs[b].get(key)
                if rb is None:
                    findings["missing"].append(dict(a=a, b=b, key=list(map(str, key))))
                    continue
                if ra != rb:
                    cross_ok = TYPES[t]["cross"]
                    same_family = Path(a).stem.rsplit("-", 1)[0] == Path(b).stem.rsplit("-", 1)[0]
                    if (cross_ok or same_family) and not (is_known(known, a, t, key[3]) or is_known(known, b, t, key[3])):
                        findings["runs"].append(dict(a=a, b=b, type=t, value=key[1], op=key[2], container=key[3], ra=ra, rb=rb))
    return dict(cells=total, runs=names, known=dict(known_hits), findings={k: v for k, v in findings.items()})


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--analyze", nargs="+")
    parser.add_argument("--json")
    args = parser.parse_args()
    if args.analyze:
        result = analyze(args.analyze)
        counts = {k: len(v) for k, v in result["findings"].items()}
        print(f"cells: {result['cells']}, findings: {counts or 'none'}, known issue hits: {result['known'] or 'none'}")
        for kind, items in result["findings"].items():
            for item in items[:12]:
                print(" ", kind, json.dumps(item))
        if args.json:
            Path(args.json).write_text(json.dumps(result, indent=1))
        return 1 if result["findings"] else 0
    text = emit_module()
    if args.write:
        TARGET.write_text(text)
        subprocess.run(["moon", "fmt"], cwd=ROOT, capture_output=True)
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
