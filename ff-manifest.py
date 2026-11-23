#!/usr/bin/env python3
"""Capture and diff the effective FaceFusion invocation of every ff-*.sh script.

A refactor of these scripts can silently change the command actually run — a
flag dropped from a parameterised wrapper, a `cd` moved into a subshell, a
conda activation that no longer reaches the python call. None of those crash.
They produce different output.

This tool records the contract each script currently honours (working
directory, conda environment, and the exact command line) and lets you diff it
after each refactor stage.

Usage:
    ./ff-manifest.py --save          # write .ff-manifest.baseline (repo root)
    ./ff-manifest.py                 # print current manifest
    ./ff-manifest.py --check         # diff current vs baseline; exit 1 on drift
    ./ff-manifest.py --save --force  # deliberately re-baseline
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
BASELINE = HERE / ".ff-manifest.baseline"
LIBRARY = "ff-lib.sh"
COMMAND_RE = re.compile(
    r'(?:"\$FF_PYTHON"\s+"\$FF_ENTRY"|python\s+[^\n]*?(?:no_reject|facefusion)\.py)[^\n]*'
)
CD_RE = re.compile(r"^\s*cd\s+(\S+)")
CONDA_RE = re.compile(r"conda\s+activate\s+(\S+)")
LIB_RE = re.compile(r'source\s+"\$\{0:A:h\}/([^"]+)"')

# Values ff-lib.sh resolves at runtime. They are not in the script text, so the
# gate cannot see them without asking the library - and some of them come from
# outside the repo entirely (the install's own facefusion.ini, its metadata.py).
RESOLVED = ("app_dir", "python", "entry", "version", "filter", "output_dir")
RESOLVE_SNIPPET = (
    'source ./%s >/dev/null 2>&1; '
    'print -r -- "$FF_APP_DIR"; print -r -- "$FF_PYTHON"; print -r -- "$FF_ENTRY"; '
    'print -r -- "$FF_VERSION"; print -r -- "$FF_FILTER"; print -r -- "$OUTPUT_DIR"'
) % LIBRARY


def redact(value: str) -> str:
    """Keep the baseline free of this machine's absolute paths."""
    return value.replace(str(Path.home()), "$HOME")


def logical_lines(text: str) -> list[str]:
    """Join backslash continuations into single logical lines."""
    out: list[str] = []
    buf = ""
    for raw in text.splitlines():
        line = raw.rstrip()
        if buf:
            buf += " " + line
        else:
            buf = line
        if buf.endswith("\\"):
            buf = buf[:-1].rstrip()
            continue
        out.append(buf)
        buf = ""
    if buf:
        out.append(buf)
    return out


def squash(s: str) -> str:
    """Collapse whitespace so cosmetic reformatting is not reported as drift."""
    return " ".join(s.split())


def strip_trailing_punct(s: str) -> str:
    return s.strip().rstrip(";").strip('"').strip("'").strip()


def manifest_entry(path: Path) -> str:
    text = path.read_text(errors="ignore")
    cwd = conda = lib = ""
    commands: list[str] = []

    for line in logical_lines(text):
        if not cwd:
            m = CD_RE.match(line)
            if m:
                cwd = strip_trailing_punct(m.group(1))
        if not conda:
            m = CONDA_RE.search(line)
            if m:
                conda = strip_trailing_punct(m.group(1))
        if not lib:
            m = LIB_RE.search(line)
            if m:
                lib = m.group(1)
        for m in COMMAND_RE.finditer(line):
            commands.append(squash(m.group(0)).rstrip(";").strip())

    lines = [f"### {path.name}", f"cwd:   {cwd or '<none>'}", f"conda: {conda or '<none>'}",
             f"lib:   {lib or '<none>'}"]
    if commands:
        for i, c in enumerate(commands, 1):
            lines.append(f"cmd{i}:  {c}")
    else:
        lines.append("cmd:   <none>")
    return "\n".join(lines)


def resolved_block() -> str:
    """Ask ff-lib.sh what it actually resolves, rather than re-implementing it."""
    try:
        done = subprocess.run(
            ["zsh", "-c", RESOLVE_SNIPPET],
            cwd=str(HERE), capture_output=True, text=True, timeout=60,
        )
        values = done.stdout.splitlines()
    except (OSError, subprocess.SubprocessError):
        values = []
    values += [""] * (len(RESOLVED) - len(values))

    lines = ["### resolved (via ff-lib.sh - environment, not script text)"]
    for name, value in zip(RESOLVED, values):
        lines.append(f"{name + ':':<12}{redact(value) if value else '<unresolved>'}")
    return "\n".join(lines)


def build() -> str:
    entries = []
    for p in sorted(HERE.glob("ff-*.sh")):
        if p.name in (Path(__file__).name, LIBRARY):
            continue
        entries.append(manifest_entry(p))
    return resolved_block() + "\n\n" + "\n\n".join(entries) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--save", action="store_true", help="write the baseline")
    ap.add_argument("--check", action="store_true", help="diff against the baseline")
    ap.add_argument("--force", action="store_true", help="overwrite an existing baseline")
    args = ap.parse_args()

    current = build()

    if args.save:
        if BASELINE.exists() and not args.force:
            print(f"baseline already exists: {BASELINE}", file=sys.stderr)
            print("refusing to overwrite without --force", file=sys.stderr)
            return 1
        BASELINE.write_text(current)
        print(f"baseline written: {BASELINE} ({len(current.splitlines())} lines)")
        return 0

    if args.check:
        if not BASELINE.exists():
            print(f"no baseline at {BASELINE} — run --save first", file=sys.stderr)
            return 2
        expected = BASELINE.read_text()
        if expected == current:
            print("OK: every script still emits its recorded cwd, conda env and command")
            return 0
        import difflib
        diff = difflib.unified_diff(
            expected.splitlines(), current.splitlines(),
            fromfile="baseline", tofile="current", lineterm="")
        print("\n".join(diff))
        print("\nDRIFT: a script's effective invocation changed", file=sys.stderr)
        return 1

    print(current, end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
