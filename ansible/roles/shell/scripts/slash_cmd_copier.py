#!/usr/bin/env python3
"""Copy slash command prompts to the clipboard."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


def _commands_dir() -> Path:
    """Return the path to the slash commands directory."""
    return Path.home() / ".local" / "slash" / "commands"


def _copy_prompt(command_name: str) -> int:
    """Copy the specified prompt file to the clipboard."""
    commands_dir = _commands_dir()
    prompt_file = commands_dir / f"{command_name}.md"

    if not prompt_file.is_file():
        print(
            f"Error: Prompt file not found for command '/{command_name}'",
            file=sys.stderr,
        )
        return 1

    try:
        content = prompt_file.read_text(encoding="utf-8")
    except OSError as exc:
        print(f"Error: Failed to read prompt file. {exc}", file=sys.stderr)
        return 1

    try:
        subprocess.run(["pbcopy"], input=content.encode("utf-8"), check=True)
    except FileNotFoundError:
        print("Error: 'pbcopy' command not found on this system.", file=sys.stderr)
        return 1
    except subprocess.CalledProcessError as exc:
        print(
            f"Error: pbcopy failed with exit code {exc.returncode}",
            file=sys.stderr,
        )
        return 1
    except Exception as exc:  # pragma: no cover - safeguard
        print(f"Error: Failed to copy prompt. {exc}", file=sys.stderr)
        return 1

    print(f"✅ Copied prompt for '/{command_name}' to clipboard")
    return 0


def main() -> int:
    """Entry point for the slash command copier."""
    if len(sys.argv) != 2:
        print("Usage: slash_cmd_copier.py <command_name>", file=sys.stderr)
        return 1

    command_name = sys.argv[1].strip()
    if not command_name:
        print("Error: Command name cannot be empty.", file=sys.stderr)
        return 1

    return _copy_prompt(command_name)


if __name__ == "__main__":
    sys.exit(main())
