#!/usr/bin/env python3
import json
import os
import subprocess
import sys


def get_file_path() -> str:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError):
        data = {}

    if isinstance(data, dict):
        file_path = data.get("tool_input", {}).get("file_path", "")
        if file_path:
            return file_path

    file_path = os.environ.get("CLAUDE_FILE_PATH", "")
    if file_path:
        return file_path

    return ""


def get_command(file_path: str) -> list[str] | None:
    if file_path.endswith(".mbt.md"):
        return ["moon", "check", file_path]

    _, ext = os.path.splitext(file_path)

    if ext == ".nix":
        return ["nixfmt", file_path]
    if ext in (".ts", ".tsx"):
        return ["vp", "check", "--fix", file_path]
    if ext == ".go":
        return ["gofmt", "-w", file_path]
    if ext == ".mbt":
        return ["moon", "check", file_path]

    return ["vp", "check", "--fix", file_path]


def main() -> int:
    file_path = get_file_path()
    if not file_path or not os.path.isfile(file_path):
        return 0

    cmd = get_command(file_path)
    if cmd is None:
        return 0

    file_dir = os.path.dirname(file_path) or "."

    result = subprocess.run(
        cmd,
        cwd=file_dir,
        capture_output=True,
        text=True,
    )

    if result.stdout:
        sys.stdout.write(result.stdout)
    if result.stderr:
        sys.stderr.write(result.stderr)

    if result.returncode != 0:
        return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
