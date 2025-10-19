#!/usr/bin/env python3
"""Generate Gemini CLI command definitions from shared configuration."""

from __future__ import annotations

import json
from pathlib import Path

from slash_generator import BaseSlashGenerator, SlashCommand


class GeminiGenerator(BaseSlashGenerator):
    """Generator for Gemini commands."""

    @property
    def default_destination(self) -> Path:
        return Path.home() / ".gemini/commands"

    def render(self, command: SlashCommand, prompt_content: str) -> tuple[str, str]:
        description_json = json.dumps(command.description, ensure_ascii=False)
        toml_body = (
            f"description = {description_json}\n\n"
            'prompt = """\n'
            f"{prompt_content}\n"
            '"""\n'
        )
        return f"{command.key}.toml", toml_body


if __name__ == "__main__":  # pragma: no cover - CLI entrypoint
    import sys

    raise SystemExit(BaseSlashGenerator.main(GeminiGenerator, sys.argv[1:]))
