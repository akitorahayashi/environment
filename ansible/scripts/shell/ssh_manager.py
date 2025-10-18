#!/usr/bin/env python3
"""Manage SSH keys and per-host configuration snippets."""

from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path

import typer
from rich.console import Console

VALID_KEY_TYPES = ("ed25519", "rsa", "ecdsa")
HOST_PATTERN = re.compile(r"^[A-Za-z0-9._-]+$")

app = typer.Typer(help="Manage SSH keys and per-host configuration snippets.")
console = Console(highlight=False)
err_console = Console(stderr=True, highlight=False)


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


def _handle_generate_key(host: str, key_type: str) -> None:
    if key_type not in VALID_KEY_TYPES:
        err_console.print(
            f"Error: Unsupported key type '{key_type}' (allowed: {('|'.join(VALID_KEY_TYPES))})."
        )
        raise typer.Exit(1)

    if not HOST_PATTERN.match(host):
        err_console.print(f"Error: Invalid host '{host}' (allowed: [A-Za-z0-9._-]+).")
        raise typer.Exit(1)

    ssh_dir = _ssh_dir()
    conf_dir = _conf_dir()
    ssh_dir.mkdir(parents=True, exist_ok=True)
    conf_dir.mkdir(parents=True, exist_ok=True)

    key_path = ssh_dir / f"id_{key_type}_{host}"
    config_path = conf_dir / f"{host}.conf"

    if config_path.exists():
        err_console.print(f"Error: Config for host '{host}' already exists.")
        raise typer.Exit(1)

    if key_path.exists() or Path(str(key_path) + ".pub").exists():
        err_console.print(f"Error: Key files already exist: '{key_path}'(.pub).")
        raise typer.Exit(1)

    try:
        _run_ssh_keygen(key_type, key_path, host)
        _write_host_config(host, key_type, config_path)
    except (subprocess.CalledProcessError, FileNotFoundError) as exc:
        # Best-effort cleanup
        for p in (key_path, Path(str(key_path) + ".pub")):
            try:
                if p.exists():
                    p.unlink()
            except OSError:
                pass
        err_console.print(f"Error: {exc}")
        raise typer.Exit(1)

    pub_key_path = Path(str(key_path) + ".pub")
    console.print(f"✅ SSH key and config for '{host}' created.")
    if pub_key_path.exists():
        console.print("🔑 Public key:")
        console.print(pub_key_path.read_text().strip())


@app.command("gk")
def generate_key(
    key_type: str = typer.Argument(..., help="SSH key type", metavar="TYPE"),
    host: str = typer.Argument(..., help="Host alias"),
) -> None:
    """Generate a key and config snippet for a host."""

    _handle_generate_key(host, key_type)


@app.command("ls")
def list_hosts() -> None:
    conf_dir = _conf_dir()
    if not conf_dir.exists():
        return

    for conf_file in sorted(conf_dir.glob("*.conf")):
        console.print(conf_file.stem)


@app.command("rm")
def remove_host(
    host: str = typer.Argument(..., help="Host alias"),
) -> None:
    # Validate and constrain to conf.d
    if not HOST_PATTERN.match(host):
        err_console.print(f"Error: Invalid host '{host}' (allowed: [A-Za-z0-9._-]+).")
        raise typer.Exit(1)
    conf_dir = _conf_dir()
    base = conf_dir.resolve()
    config_path = (conf_dir / f"{host}.conf").resolve()
    try:
        config_path.relative_to(base)
    except ValueError:
        err_console.print(f"Error: Refusing to operate outside {base}.")
        raise typer.Exit(1)

    if not config_path.exists():
        err_console.print(f"Error: Config for host '{host}' not found.")
        raise typer.Exit(1)

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
        console.print(f"🗑️ Removed key files for {host}.")

    config_path.unlink()
    console.print(f"🗑️ Removed config file for '{host}'.")


def main() -> None:
    app()


if __name__ == "__main__":  # pragma: no cover - CLI entry
    main()
