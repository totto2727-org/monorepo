#!/usr/bin/env python3
"""Configure an optional authenticated binary cache without replacing Nix defaults."""

from collections.abc import Mapping
import os
from pathlib import Path
import shutil
import sys
import tempfile
from urllib.parse import urlsplit


def configure(env: Mapping[str, str]) -> None:
    url, key, username, password = (
        env.get(name, "") for name in
        ("CACHE_URL", "CACHE_PUBLIC_KEY", "CACHE_USERNAME", "CACHE_PASSWORD")
    )
    if not any((url, key, username, password)):
        return
    if not url or not key or bool(username) != bool(password):
        raise ValueError("incomplete cache inputs")
    # Values are written to line-oriented configuration files.
    if any("\n" in value or "\r" in value for value in (url, key, username, password)):
        raise ValueError("multiline cache input")
    override = env.get("NIX_USER_CONF_FILES")
    config = Path(override.split(":")[-1]) if override else (
        Path(env.get("XDG_CONFIG_HOME") or Path(env["HOME"]) / ".config") / "nix/nix.conf"
    )
    directory = None
    try:
        settings = f"\nextra-substituters = {url}\nextra-trusted-public-keys = {key}\n"
        if username:
            hostname = urlsplit(url).hostname
            if hostname is None:
                raise ValueError("cache hostname required for netrc")
            directory = Path(tempfile.mkdtemp(prefix="setup-nix-cache-", dir=env["RUNNER_TEMP"]))
            netrc = directory / "netrc"
            fd = os.open(netrc, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            with os.fdopen(fd, "w") as stream:
                for name, value in (("machine", hostname), ("login", username), ("password", password)):
                    quoted = value.replace("\\", "\\\\").replace('"', '\\"')
                    stream.write(f'{name} "{quoted}"\n')
            settings += f"netrc-file = {netrc}\n"
        config.parent.mkdir(parents=True, exist_ok=True)
        with config.open("a") as stream:
            stream.write(settings)
    except Exception:
        if directory is not None:
            shutil.rmtree(directory)
        raise


def main() -> int:
    try:
        configure(os.environ)
    except Exception:
        print("::error::Unable to configure the Nix cache. Check inputs and writable configuration paths.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
