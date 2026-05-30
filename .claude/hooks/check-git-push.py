#!/usr/bin/env python3
import json
import os
import subprocess
import sys


def get_command() -> str:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError):
        data = {}

    if isinstance(data, dict):
        command = data.get("tool_input", {}).get("command", "")
        if command:
            return command

    command = os.environ.get("TOOL_INPUT_command", "")
    if command:
        return command

    raw = os.environ.get("CLAUDE_TOOL_INPUT", "")
    if raw:
        try:
            return json.loads(raw).get("command", "")
        except json.JSONDecodeError:
            pass

    return ""


def main() -> int:
    command = get_command()
    if not command or "git" not in command or "push" not in command:
        return 0

    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", ".")
    result = subprocess.run(
        ["vp", "run", "ci"],
        cwd=project_dir,
        capture_output=True,
        text=True,
    )

    sys.stdout.write(result.stdout)
    sys.stderr.write(result.stderr)
    return result.returncode


if __name__ == "__main__":
    sys.exit(main())
