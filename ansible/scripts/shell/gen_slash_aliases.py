#!/usr/bin/env python3
"""Generate shell aliases for slash command prompts."""

from __future__ import annotations

import argparse
import os
import shlex
import sys
from pathlib import Path

_DOC_FILENAMES = frozenset(("README", "AGENTS", "CLAUDE", "GEMINI"))


def _commands_dir() -> Path:
    """Return the path to the slash commands directory."""
    return Path(
        os.environ.get(
            "SLASH_COMMANDS_DIR", Path.home() / ".local" / "slash" / "commands"
        )
    )


def _collect_alias_entries(commands_dir: Path) -> list[tuple[str, str]]:
    """Return (alias, command_path) entries for prompt files."""

    entries: list[tuple[str, str]] = []
    seen_aliases: set[str] = set()
    basename_index: dict[str, set[str]] = {}

    for prompt_file in sorted(commands_dir.rglob("*.md")):
        relative_path = prompt_file.relative_to(commands_dir).with_suffix("")
        command_path = relative_path.as_posix()
        if not command_path:
            continue

        # Skip documentation files
        if relative_path.name in _DOC_FILENAMES:
            continue

        basename = relative_path.name
        basename_index.setdefault(basename, set()).add(command_path)

    for basename, command_paths in basename_index.items():
        if len(command_paths) != 1:
            continue

        command_path = next(iter(command_paths))

        alias_name = f"sl-{basename}"
        if alias_name in seen_aliases:
            continue

        seen_aliases.add(alias_name)
        entries.append((alias_name, command_path))

    entries.sort(key=lambda item: item[0])
    return entries


def _iter_aliases(alias_entries: list[tuple[str, str]]) -> list[str]:
    """Return alias definitions for all prompt files in the directory."""

    return [
        f'alias {alias_name}="slash_cmd_copier.py {shlex.quote(command_path)}"'
        for alias_name, command_path in alias_entries
    ]


def _format_alias_listing(alias_entries: list[tuple[str, str]]) -> str:
    """Return a formatted list of alias mappings."""

    if not alias_entries:
        return ""

    width = max(len(alias_name) for alias_name, _ in alias_entries)
    lines = [
        f"{alias_name.ljust(width)}  /{command_path}"
        for alias_name, command_path in alias_entries
    ]
    return "\n".join(lines)


def _parse_args(argv: list[str]) -> argparse.Namespace:
    """Parse CLI arguments for the script."""

    parser = argparse.ArgumentParser(
        description="Generate shell aliases for slash command prompts.",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List available slash aliases instead of emitting shell definitions.",
    )
    return parser.parse_args(argv)


def main() -> int:
    """Print alias definitions for all slash commands."""
    args = _parse_args(sys.argv[1:])
    commands_dir = _commands_dir()
    if not commands_dir.exists() or not commands_dir.is_dir():
        return 0

    alias_entries = _collect_alias_entries(commands_dir)

    if args.list:
        listing = _format_alias_listing(alias_entries)
        if listing:
            print(listing)
    else:
        aliases = _iter_aliases(alias_entries)
        if aliases:
            print("\n".join(aliases))

    return 0


if __name__ == "__main__":
    sys.exit(main())
