#!/usr/bin/env python3
"""Utilities for generating slash command assets from JSON configuration."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List


class SlashGeneratorError(RuntimeError):
    """Raised when slash command generation fails."""


@dataclass(slots=True)
class SlashCommand:
    """A single slash command specification."""

    key: str
    title: str
    description: str
    prompt_file: str


def _read_json(path: Path) -> Dict[str, object]:
    try:
        raw = path.read_text(encoding="utf-8")
    except FileNotFoundError as exc:  # pragma: no cover - handled in caller
        raise SlashGeneratorError(f"Config file not found: {path}") from exc
    except OSError as exc:  # pragma: no cover - unexpected IO error
        raise SlashGeneratorError(f"Failed to read config file: {path}") from exc

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise SlashGeneratorError(f"Invalid JSON in {path}: {exc}") from exc

    if not isinstance(data, dict):
        raise SlashGeneratorError("Configuration root must be an object.")
    return data


def load_commands(config_path: Path) -> List[SlashCommand]:
    """Load command definitions from the JSON configuration."""

    data = _read_json(config_path)
    commands = data.get("commands")
    if not isinstance(commands, dict):
        raise SlashGeneratorError("'commands' must be an object in the config file.")

    results: List[SlashCommand] = []
    for key, value in commands.items():
        if not isinstance(key, str):
            raise SlashGeneratorError("Command keys must be strings.")
        if not isinstance(value, dict):
            raise SlashGeneratorError(f"Command '{key}' must be an object.")

        title = value.get("title")
        description = value.get("description")
        prompt_file = value.get("prompt-file")

        if not isinstance(title, str) or not isinstance(description, str):
            raise SlashGeneratorError(
                f"Command '{key}' must include string 'title' and 'description'."
            )
        if not isinstance(prompt_file, str):
            raise SlashGeneratorError(
                f"Command '{key}' must include a string 'prompt-file'."
            )

        results.append(
            SlashCommand(
                key=key,
                title=title,
                description=description,
                prompt_file=prompt_file,
            )
        )

    return results


def ensure_prompt_exists(prompt_root: Path, prompt_file: str) -> Path:
    """Return the resolved path to a prompt file, ensuring it exists."""

    prompt_path = (prompt_root / prompt_file).resolve()
    if not prompt_path.is_file():
        raise SlashGeneratorError(f"Prompt file not found: {prompt_path}")
    if Path(prompt_root).resolve() not in prompt_path.parents:
        raise SlashGeneratorError(
            f"Prompt file must be inside the prompt directory: {prompt_path}"
        )
    return prompt_path


def clean_destination(directory: Path) -> None:
    """Ensure the destination directory exists and remove any existing files."""

    directory.mkdir(parents=True, exist_ok=True)
    for path in directory.iterdir():
        if path.is_file() or path.is_symlink():
            path.unlink()


def _escape_yaml_string(value: str) -> str:
    """Escape a string for inclusion in simple YAML front matter."""

    escaped = value.replace("\\", "\\\\").replace("\"", "\\\"")
    return escaped


def generate_claude(
    commands: Iterable[SlashCommand],
    *,
    prompt_root: Path,
    destination: Path,
) -> None:
    """Generate Markdown prompt files for Claude."""

    clean_destination(destination)

    for command in commands:
        prompt_path = ensure_prompt_exists(prompt_root, command.prompt_file)
        output_file = destination / f"{command.key}.md"

        front_matter = (
            "---\n"
            f'title: "{_escape_yaml_string(command.title)}"\n'
            f'description: "{_escape_yaml_string(command.description)}"\n'
            "---\n\n"
        )
        prompt_content = prompt_path.read_text(encoding="utf-8")
        output_file.write_text(front_matter + prompt_content, encoding="utf-8")


def generate_codex(
    commands: Iterable[SlashCommand],
    *,
    prompt_root: Path,
    destination: Path,
) -> None:
    """Generate Markdown prompt files for Codex."""

    clean_destination(destination)

    for command in commands:
        prompt_path = ensure_prompt_exists(prompt_root, command.prompt_file)
        safe_key = command.key
        if not all(ch.isalnum() or ch in {"_", "-", "."} for ch in safe_key):
            raise SlashGeneratorError(
                f"Invalid command key '{command.key}' (contains unsafe characters)."
            )
        if safe_key != command.key:
            raise SlashGeneratorError(
                f"Command key '{command.key}' does not round-trip to safe filename."
            )

        output_file = destination / f"{safe_key}.md"
        prompt_content = prompt_path.read_text(encoding="utf-8")
        output_file.write_text(prompt_content, encoding="utf-8")


def generate_gemini(
    commands: Iterable[SlashCommand],
    *,
    prompt_root: Path,
    destination: Path,
) -> None:
    """Generate TOML prompt files for Gemini."""

    clean_destination(destination)

    for command in commands:
        prompt_path = ensure_prompt_exists(prompt_root, command.prompt_file)
        prompt_content = prompt_path.read_text(encoding="utf-8")
        description_json = json.dumps(command.description, ensure_ascii=False)

        output_file = destination / f"{command.key}.toml"
        toml_body = (
            f"description = {description_json}\n\n"
            "prompt = \"\"\"\n"
            f"{prompt_content}\n"
            "\"\"\"\n"
        )
        output_file.write_text(toml_body, encoding="utf-8")
