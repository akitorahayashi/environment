"""Backup installed VSCode extensions to a JSON file."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

CANDIDATE_COMMANDS = (
    "code",
    "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code",
    "code-insiders",
)


class ExtensionBackupError(RuntimeError):
    """Raised when the VSCode extensions backup fails."""


def detect_command() -> str:
    for candidate in CANDIDATE_COMMANDS:
        if os.path.isabs(candidate) and Path(candidate).exists():
            return candidate
        if shutil.which(candidate):
            return candidate
    raise ExtensionBackupError(
        "VSCode command (code or code-insiders) not found in PATH or default locations."
    )


def list_extensions(command: str) -> list[str]:
    try:
        completed = subprocess.run(
            [command, "--list-extensions"],
            capture_output=True,
            text=True,
            check=True,
            timeout=10,
        )
    except FileNotFoundError as exc:
        raise ExtensionBackupError(
            f"Command '{command}' is not available on this system."
        ) from exc
    except subprocess.TimeoutExpired as exc:
        raise ExtensionBackupError(
            f"Timed out while running '{command} --list-extensions'."
        ) from exc
    except subprocess.CalledProcessError as exc:
        raise ExtensionBackupError(
            "Failed to get VSCode extensions. "
            "If VSCode is running, close it and try again."
        ) from exc

    return [line.strip() for line in completed.stdout.splitlines() if line.strip()]


def write_backup(destination: Path, extensions: list[str]) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    payload = {"extensions": extensions}
    destination.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )


def run(config_dir: Path, output: Path | None = None) -> int:
    """Execute the VSCode extensions backup.

    Args:
        config_dir: Configuration directory for output.
        output: Optional override for output file location.

    Returns:
        Exit code (0 on success, 1 on failure).
    """
    try:
        output_file = output or (config_dir / "vscode-extensions.json")
        command = detect_command()
        extensions = list_extensions(command)
        write_backup(output_file, extensions)
    except ExtensionBackupError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1

    print(f"VSCode extensions list backed up to: {output_file}")
    return 0
