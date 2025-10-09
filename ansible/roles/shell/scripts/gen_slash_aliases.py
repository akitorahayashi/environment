#!/usr/bin/env python3
"""Generate shell aliases for slash command prompts."""

from __future__ import annotations

import os
import sys
from pathlib import Path


def _commands_dir() -> Path:
    """Return the path to the slash commands directory."""
    return Path(
        os.environ.get(
            "SLASH_COMMANDS_DIR", Path.home() / ".local" / "slash" / "commands"
        )
    )


def _iter_aliases(commands_dir: Path) -> list[str]:
    """Return alias definitions for all prompt files in the directory."""
    aliases: list[str] = []
    for prompt_file in sorted(commands_dir.rglob("*.md")):
        command_name = str(prompt_file.relative_to(commands_dir).with_suffix('')).replace(os.sep, '-')
        if not command_name:
            continue
        alias_name = f"sl-{command_name}"
        aliases.append(f'alias {alias_name}="slash_cmd_copier.py {command_name}"')
    return aliases


def main() -> int:
    """Print alias definitions for all slash commands."""
    commands_dir = _commands_dir()
    if not commands_dir.exists() or not commands_dir.is_dir():
        return 0

    aliases = _iter_aliases(commands_dir)
    if aliases:
        print("\n".join(aliases))
    return 0


if __name__ == "__main__":
    sys.exit(main())
