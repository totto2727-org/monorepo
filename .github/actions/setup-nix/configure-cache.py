#!/usr/bin/env python3
"""Configure an optional authenticated binary cache without replacing Nix defaults."""

from collections.abc import Mapping
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from urllib.parse import urlsplit


def token(value: str) -> bool:
    return bool(value) and not any(c.isspace() or ord(c) < 32 or ord(c) == 127 or c in "#\\" for c in value)


def configure(env: Mapping[str, str]) -> None:
    url, key, username, password = (
        env.get(name, "") for name in
        ("CACHE_URL", "CACHE_PUBLIC_KEY", "CACHE_USERNAME", "CACHE_PASSWORD")
    )
    if not any((url, key, username, password)):
        return
    if not url or not key or bool(username) != bool(password):
        raise ValueError("invalid inputs")
    if not token(url) or any(c in url for c in "#?"):
        raise ValueError("invalid URL")
    parsed = urlsplit(url)
    if (parsed.scheme != "https" or not parsed.hostname or parsed.username is not None
            or parsed.password is not None or parsed.query or parsed.fragment):
        raise ValueError("invalid URL")
    # Accessing port also validates malformed and out-of-range ports.
    parsed.port
    if not token(parsed.hostname) or not token(key):
        raise ValueError("invalid configuration token")
    if username and (not all(token(v) and '"' not in v for v in (parsed.hostname, username, password)) or ":" in username):
        raise ValueError("invalid credentials")
    override = env.get("NIX_USER_CONF_FILES")
    if override is not None:
        paths = override.split(":")
        if not all(p and Path(p).is_absolute() for p in paths):
            raise ValueError("unsupported user configuration override")
        config = Path(paths[-1])
    else:
        home = env.get("XDG_CONFIG_HOME") or (str(Path(env["HOME"]) / ".config") if env.get("HOME") else "")
        if not home:
            raise ValueError("missing user configuration directory")
        config = Path(home) / "nix/nix.conf"
    runner_temp = None
    if username:
        if not env.get("RUNNER_TEMP"):
            raise ValueError("missing temporary directory")
        runner_temp = Path(env["RUNNER_TEMP"]).resolve()
        if not token(str(runner_temp)) or not runner_temp.is_dir():
            raise ValueError("invalid temporary directory")
    probe = subprocess.run(
        ["nix", "--extra-experimental-features", "nix-command", "store", "info", "--json"],
        env=dict(os.environ) | env, capture_output=True, text=True, check=True, timeout=30,
    )
    if json.loads(probe.stdout).get("trusted") is not True:
        raise ValueError("trusted Nix client required")
    directory = None
    try:
        settings = f"\nextra-substituters = {url}\nextra-trusted-public-keys = {key}\n"
        if username:
            directory = Path(tempfile.mkdtemp(prefix="setup-nix-cache-", dir=runner_temp))
            directory.chmod(0o700)
            netrc = directory / "netrc"
            fd = os.open(netrc, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            with os.fdopen(fd, "w") as stream:
                stream.write(f"machine {parsed.hostname}\nlogin {username}\npassword {password}\n")
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
        print("::error::Unable to configure the Nix cache. Check inputs, Nix store trust, and writable configuration paths.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
