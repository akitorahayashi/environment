#!/usr/bin/env python3
"""Generate Claude slash commands from the shared configuration."""

from __future__ import annotations

from pathlib import Path

from slash_generator import BaseSlashGenerator, SlashCommand


class ClaudeGenerator(BaseSlashGenerator):
    """Generator for Claude slash commands."""

    @property
    def default_destination(self) -> Path:
        return Path.home() / ".claude/commands"

    def render(self, command: SlashCommand, prompt_content: str) -> tuple[str, str]:
        front_matter = (
            "---\n"
            f'title: "{BaseSlashGenerator._escape_yaml_string(command.title)}"\n'
            f'description: "{BaseSlashGenerator._escape_yaml_string(command.description)}"\n'
            "---\n\n"
        )
        return f"{command.key}.md", front_matter + prompt_content


if __name__ == "__main__":  # pragma: no cover - CLI entrypoint
    import sys

    raise SystemExit(BaseSlashGenerator.main(ClaudeGenerator, sys.argv[1:]))
