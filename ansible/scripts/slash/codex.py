#!/usr/bin/env python3
"""Generate Codex prompts from the shared slash command configuration."""

from __future__ import annotations

from pathlib import Path

from slash_generator import BaseSlashGenerator, SlashCommand, SlashGeneratorError


class CodexGenerator(BaseSlashGenerator):
    """Generator for Codex prompts."""

    @property
    def default_destination(self) -> Path:
        return Path.home() / ".codex/prompts"

    def render(self, command: SlashCommand, prompt_content: str) -> tuple[str, str]:
        safe_key = command.key
        if not all(ch.isalnum() or ch in {"_", "-", "."} for ch in safe_key):
            raise SlashGeneratorError(
                f"Invalid command key '{command.key}' (contains unsafe characters)."
            )
        return f"{safe_key}.md", prompt_content


if __name__ == "__main__":  # pragma: no cover - CLI entrypoint
    import sys

    raise SystemExit(BaseSlashGenerator.main(CodexGenerator, sys.argv[1:]))
