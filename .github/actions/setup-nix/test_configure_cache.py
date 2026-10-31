"""Standalone regression tests. Run with python3 -m unittest discover -s this directory."""

import base64
import importlib.util
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("configure_cache", HERE / "configure-cache.py")
HELPER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(HELPER)
KEY = "test.example-1:" + base64.b64encode(bytes(32)).decode()


class CacheTests(unittest.TestCase):
    def setUp(self):
        scratch = HERE.parents[2] / "tmp"
        scratch.mkdir(exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=scratch)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.config = self.root / ".config/nix/nix.conf"
        self.env = {
            "HOME": str(self.root), "RUNNER_TEMP": str(self.root),
            "NIX_REMOTE": "local?root=" + str(self.root / "store"),
            "CACHE_URL": "https://cache.example/store", "CACHE_PUBLIC_KEY": KEY,
            "CACHE_USERNAME": "cache-user", "CACHE_PASSWORD": "opaque:$!=+/@%&'token",
        }
        if not shutil.which("nix"):
            stub = self.root / "nix"
            stub.write_text('#!/usr/bin/env python3\nprint(\'{"trusted": true}\')\n')
            stub.chmod(0o700)
            self.env["PATH"] = str(self.root) + os.pathsep + os.environ.get("PATH", "")

    def run_cli(self):
        env = {k: v for k, v in os.environ.items() if not k.startswith(("NIX_", "CACHE_", "XDG_CONFIG"))}
        return subprocess.run([sys.executable, str(HERE / "configure-cache.py")],
                              env=env | self.env, capture_output=True, text=True)

    def test_disabled(self):
        HELPER.configure({})
        self.assertFalse(self.config.exists())

    def test_authenticated_permissions_and_no_secret_in_config(self):
        result = self.run_cli()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout + result.stderr, "")
        text = self.config.read_text()
        self.assertNotIn(self.env["CACHE_PASSWORD"], text)
        netrc = Path(text.split("netrc-file = ")[1].strip())
        self.assertEqual(stat.S_IMODE(netrc.stat().st_mode), 0o600)
        self.assertEqual(stat.S_IMODE(netrc.parent.stat().st_mode), 0o700)
        self.assertEqual(netrc.read_text(), "machine cache.example\nlogin cache-user\npassword " + self.env["CACHE_PASSWORD"] + "\n")

    def test_public_cache_has_no_credentials(self):
        self.env.update(CACHE_USERNAME="", CACHE_PASSWORD="")
        HELPER.configure(self.env)
        self.assertNotIn("netrc-file", self.config.read_text())
        self.assertEqual(list(self.root.glob("setup-nix-cache-*")), [])

    def test_ipv6_and_port(self):
        self.env["CACHE_URL"] = "https://[2001:db8::1]:8443/store"
        HELPER.configure(self.env)
        netrc = next(self.root.glob("setup-nix-cache-*/netrc"))
        self.assertTrue(netrc.read_text().startswith("machine 2001:db8::1\n"))

    def test_existing_configuration_preserved(self):
        self.config.parent.mkdir(parents=True)
        existing = "# retained\nextra-substituters = https://magic.example\nrequire-sigs = true"
        self.config.write_text(existing)
        HELPER.configure(self.env)
        self.assertTrue(self.config.read_text().startswith(existing + "\n"))

    def test_unique_directories(self):
        HELPER.configure(self.env)
        HELPER.configure(self.env)
        self.assertEqual(len(list(self.root.glob("setup-nix-cache-*"))), 2)

    def test_xdg_configuration(self):
        self.env["XDG_CONFIG_HOME"] = str(self.root / "xdg")
        HELPER.configure(self.env)
        self.assertTrue((self.root / "xdg/nix/nix.conf").exists())
        self.assertFalse(self.config.exists())

    def test_configuration_override(self):
        first, last = self.root / "first.conf", self.root / "last.conf"
        first.write_text("# first\n")
        self.env["NIX_USER_CONF_FILES"] = f"{first}:{last}"
        HELPER.configure(self.env)
        self.assertEqual(first.read_text(), "# first\n")
        self.assertIn("extra-substituters", last.read_text())
        self.assertFalse(self.config.exists())

    def test_failure_cleans_only_owned_directory(self):
        unrelated = self.root / "setup-nix-cache-unrelated"
        unrelated.mkdir()
        self.config.parent.mkdir(parents=True)
        self.config.mkdir()
        with self.assertRaises(OSError):
            HELPER.configure(self.env)
        self.assertEqual(list(self.root.glob("setup-nix-cache-*")), [unrelated])

    def test_exclusive_file_creation(self):
        original_open = os.open
        def exclusive_open(path, flags, *args, **kwargs):
            if flags & os.O_EXCL:
                raise FileExistsError
            return original_open(path, flags, *args, **kwargs)
        with patch.object(HELPER.os, "open", side_effect=exclusive_open):
            with self.assertRaises(FileExistsError):
                HELPER.configure(self.env)
        self.assertEqual(list(self.root.glob("setup-nix-cache-*")), [])

    def test_invalid_inputs_are_safe(self):
        cases = {
            "CACHE_URL": ["", "http://cache.example", "ftp://cache.example", "https://",
                          "https://u:p@cache.example", "https://u@cache.example", "https://cache.example?x=1",
                          "https://cache.example#frag", "https://cache.example?", "https://cache.example#",
                          "https://cache.example\nextra-substituters=x", "https://cache.example\r",
                          "https://cache.example\t", "https://cache.example/a b", "https://cache.example:bad",
                          "https://cache.example:65536", "https://[broken", "https://cache.example\\evil",
                          "https://cache.example/\x00", "https://cache.example/\x7f"],
            "CACHE_PUBLIC_KEY": ["", "bad name:key", KEY + "\n", "name:key#comment", "name:key\\suffix"],
            "CACHE_USERNAME": ["", "two words", "line\nbreak", "quote\"", "back\\slash", "\x00", "u:ser", "#comment"],
            "CACHE_PASSWORD": ["", "two words", "line\nbreak", "quote\"", "back\\slash", "\x7f", "#comment"],
            "NIX_USER_CONF_FILES": ["", "relative", ":/absolute", "/absolute:"],
        }
        for name, values in cases.items():
            for value in values:
                with self.subTest(name=name, value=repr(value)):
                    env = self.env | {name: value}
                    with self.assertRaises((ValueError, OSError)):
                        HELPER.configure(env)
                    self.assertFalse(self.config.exists())
                    self.assertEqual(list(self.root.glob("setup-nix-cache-*")), [])

    def test_invalid_temp_paths_and_missing_home(self):
        for name in ("missing", "file", "bad path", "bad#path", "bad\\path", "bad\npath"):
            path = self.root / name
            if name == "file":
                path.write_text("not a directory")
            elif name != "missing":
                path.mkdir()
            with self.subTest(name=name):
                with self.assertRaises(ValueError):
                    HELPER.configure(self.env | {"RUNNER_TEMP": str(path)})
                self.assertFalse(self.config.exists())
        for updates in ({"RUNNER_TEMP": ""}, {"HOME": "", "XDG_CONFIG_HOME": ""}):
            with self.assertRaises(ValueError):
                HELPER.configure(self.env | updates)
        self.assertEqual(list(self.root.glob("setup-nix-cache-*")), [])

    def test_opaque_key_and_unicode_tokens(self):
        self.env.update(CACHE_PUBLIC_KEY="opaque-key", CACHE_USERNAME="利用者", CACHE_PASSWORD="秘密:token")
        HELPER.configure(self.env)
        self.assertIn("extra-trusted-public-keys = opaque-key", self.config.read_text())
        self.assertIn("login 利用者", next(self.root.glob("setup-nix-cache-*/netrc")).read_text())

    def test_untrusted_store_fails_without_writes(self):
        for output in ('{"trusted":false}', '{}', '{"trusted":null}', 'not JSON'):
            response = subprocess.CompletedProcess([], 0, stdout=output)
            with self.subTest(output=output), patch.object(HELPER.subprocess, "run", return_value=response):
                with self.assertRaises(ValueError):
                    HELPER.configure(self.env)
            self.assertFalse(self.config.exists())
            self.assertEqual(list(self.root.glob("setup-nix-cache-*")), [])

    def test_cli_errors_never_echo_values(self):
        self.env["CACHE_URL"] = "https://secret-user:secret-password@cache.example"
        result = self.run_cli()
        self.assertEqual(result.returncode, 1)
        self.assertNotIn("secret-user", result.stderr)
        self.assertNotIn("secret-password", result.stderr)
        self.assertNotIn("Traceback", result.stderr)
        self.assertEqual(result.stdout, "")

    @unittest.skipUnless(shutil.which("nix"), "Nix is unavailable")
    def test_effective_configuration_with_real_nix(self):
        # Keep system configuration, but isolate all user configuration from real HOME.
        env = {k: v for k, v in os.environ.items() if not k.startswith(("NIX_", "XDG_CONFIG"))}
        first = self.root / "first.conf"
        override = str(first) + ":" + str(self.config)
        env.update(HOME=str(self.root), NIX_USER_CONF_FILES=override)
        self.config.parent.mkdir(parents=True)
        first.write_text("extra-substituters = https://magic.example\n")
        def show():
            result = subprocess.run(["nix", "--extra-experimental-features", "nix-command", "config", "show", "--json"],
                                    env=env, capture_output=True, text=True, check=True)
            return {k: v["value"] for k, v in json.loads(result.stdout).items()}
        before = show()
        HELPER.configure(self.env | {"NIX_USER_CONF_FILES": override})
        after = show()
        self.assertIn(self.env["CACHE_URL"], after["substituters"])
        self.assertIn(KEY, after["trusted-public-keys"])
        self.assertTrue(set(before["substituters"]).issubset(after["substituters"]))
        self.assertTrue(set(before["trusted-public-keys"]).issubset(after["trusted-public-keys"]))
        self.assertEqual(after["require-sigs"], before["require-sigs"])
        self.assertTrue(Path(after["netrc-file"]).is_file())

    def test_action_wiring_and_order(self):
        action = (HERE / "action.yaml").read_text()
        positions = [action.index(text) for text in
                     ("- name: Install Determinate Nix", "- name: Enable Magic Nix Cache",
                      "- name: Configure binary cache", "- name: Prepare Nix development shell")]
        self.assertEqual(positions, sorted(positions))
        for name in ("url", "public-key", "username", "password"):
            self.assertIn("${{ inputs.cache-" + name + " }}", action)
        self.assertIn('python3 "$GITHUB_ACTION_PATH/configure-cache.py"', action)
        self.assertIn("inputs.prepare-dev-shell == 'true'", action)
        self.assertNotIn("${{ inputs.cache-password }}", action.split("run:")[-1])


if __name__ == "__main__":
    unittest.main()
