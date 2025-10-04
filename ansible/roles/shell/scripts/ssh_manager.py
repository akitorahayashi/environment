#!/usr/bin/env python3
"""Manage SSH keys and per-host configuration snippets."""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

VALID_KEY_TYPES = ("ed25519", "rsa", "ecdsa")
HOST_PATTERN = re.compile(r"^[A-Za-z0-9._-]+$")


def _home() -> Path:
    return Path(os.environ.get("HOME", str(Path.home())))


def _ssh_dir() -> Path:
    return _home() / ".ssh"


def _conf_dir() -> Path:
    return _ssh_dir() / "conf.d"


def _run_ssh_keygen(key_type: str, key_path: Path, host: str) -> None:
    subprocess.run(
        [
            "ssh-keygen",
            "-q",
            "-t",
            key_type,
            "-f",
            str(key_path),
            "-C",
            host,
            "-N",
            "",
        ],
        check=True,
    )


def _write_host_config(host: str, key_type: str, config_path: Path) -> None:
    content = (
        f"Host {host}\n"
        f"  HostName {host}\n"
        "  User git\n"
        f"  IdentityFile ~/.ssh/id_{key_type}_{host}\n"
        "  IdentitiesOnly yes\n"
    )
    config_path.write_text(content)
    os.chmod(config_path, 0o600)


def _handle_generate_key(args: argparse.Namespace) -> int:
    host = args.host
    key_type = args.type

    if key_type not in VALID_KEY_TYPES:
        print(
            f"Error: Unsupported key type '{key_type}' (allowed: {('|'.join(VALID_KEY_TYPES))}).",
            file=sys.stderr,
        )
        return 1

    if not HOST_PATTERN.match(host):
        print(
            f"Error: Invalid host '{host}' (allowed: [A-Za-z0-9._-]+).",
            file=sys.stderr,
        )
        return 1

    ssh_dir = _ssh_dir()
    conf_dir = _conf_dir()
    ssh_dir.mkdir(parents=True, exist_ok=True)
    conf_dir.mkdir(parents=True, exist_ok=True)

    key_path = ssh_dir / f"id_{key_type}_{host}"
    config_path = conf_dir / f"{host}.conf"

    if config_path.exists():
        print(f"Error: Config for host '{host}' already exists.", file=sys.stderr)
        return 1

    if key_path.exists() or Path(str(key_path) + ".pub").exists():
        print(f"Error: Key files already exist: '{key_path}'(.pub).", file=sys.stderr)
        return 1

    _run_ssh_keygen(key_type, key_path, host)
    _write_host_config(host, key_type, config_path)

    pub_key_path = Path(str(key_path) + ".pub")
    print(f"✅ SSH key and config for '{host}' created.")
    if pub_key_path.exists():
        print("🔑 Public key:")
        print(pub_key_path.read_text().strip())
    return 0


def _handle_list(_: argparse.Namespace) -> int:
    conf_dir = _conf_dir()
    if not conf_dir.exists():
        return 0

    for conf_file in sorted(conf_dir.glob("*.conf")):
        print(conf_file.stem)
    return 0


def _handle_remove(args: argparse.Namespace) -> int:
    host = args.host
    config_path = _conf_dir() / f"{host}.conf"

    if not config_path.exists():
        print(f"Error: Config for host '{host}' not found.", file=sys.stderr)
        return 1

    identity_file = None
    for line in config_path.read_text().splitlines():
        stripped = line.strip()
        if stripped.lower().startswith("identityfile"):
            parts = stripped.split(None, 1)
            if len(parts) == 2:
                identity_file = Path(parts[1]).expanduser()
            break

    if identity_file:
        priv_path = identity_file
        pub_path = Path(str(identity_file) + ".pub")
        for path in (priv_path, pub_path):
            if path.exists():
                path.unlink()
        print(f"🗑️ Removed key files for {host}.")

    config_path.unlink()
    print(f"🗑️ Removed config file for '{host}'.")
    return 0


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Manage SSH keys and host configurations."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    parser_gk = subparsers.add_parser(
        "gk", help="Generate a key and config snippet for a host."
    )
    parser_gk.add_argument("type", help="SSH key type", choices=list(VALID_KEY_TYPES))
    parser_gk.add_argument("host", help="Host alias")

    parser_ls = subparsers.add_parser("ls", help="List configured hosts.")
    parser_ls.set_defaults(func=_handle_list)

    parser_rm = subparsers.add_parser(
        "rm", help="Remove a host configuration and associated keys."
    )
    parser_rm.add_argument("host", help="Host alias")

    parser_gk.set_defaults(func=_handle_generate_key)
    parser_rm.set_defaults(func=_handle_remove)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)
    handler = getattr(args, "func", None)
    if handler is None:
        parser.print_help()
        return 1
    return handler(args)


if __name__ == "__main__":  # pragma: no cover - CLI entry
    sys.exit(main())
