#!/usr/bin/env python3
import json
import os
import re
import sys


FORBIDDEN_FLAGS = [
    "--no-verify",
    "--no-gpg-sign",
]


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
    if not command:
        return 0

    if not command.lower().lstrip().startswith("git "):
        return 0

    for flag in FORBIDDEN_FLAGS:
        if flag in command:
            print(
                f"Error: The flag '{flag}' is forbidden in git commands. "
                f"It bypasses required checks or security measures.",
                file=sys.stderr,
            )
            return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
