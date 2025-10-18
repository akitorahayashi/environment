#!/usr/bin/env python3
"""Backup the installed VSCode extensions to a JSON file."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import List

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


def list_extensions(command: str) -> List[str]:
    try:
        completed = subprocess.run(
            [command, "--list-extensions"],
            capture_output=True,
            text=True,
            check=True,
        )
    except FileNotFoundError as exc:
        raise ExtensionBackupError(
            f"Command '{command}' is not available on this system."
        ) from exc
    except subprocess.CalledProcessError as exc:
        raise ExtensionBackupError(
            "Failed to get VSCode extensions. "
            "If VSCode is running, close it and try again."
        ) from exc

    lines = [line.strip() for line in completed.stdout.splitlines() if line.strip()]
    return lines


def write_backup(destination: Path, extensions: List[str]) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    payload = {"extensions": extensions}
    destination.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "config_dir",
        type=Path,
        help="Configuration directory where vscode-extensions.json should be written.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Override the output file location.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        output_file = args.output or (args.config_dir / "vscode-extensions.json")
        command = detect_command()
        extensions = list_extensions(command)
        write_backup(output_file, extensions)
    except ExtensionBackupError as exc:
        print(f"[ERROR] {exc}", file=sys.stderr)
        return 1

    print(f"VSCode extensions list backed up to: {output_file}")
    return 0


if __name__ == "__main__":  # pragma: no cover - CLI entrypoint
    raise SystemExit(main())
