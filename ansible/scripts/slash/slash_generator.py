#!/usr/bin/env python3
"""Generate slash command assets from shared configuration."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Dict, Iterable, List, Tuple

import yaml


class SlashGeneratorError(RuntimeError):
    """Raised when slash command generation fails."""


@dataclass(slots=True)
class SlashCommand:
    """A single slash command specification."""

    key: str
    title: str
    description: str
    prompt_file: str


def _read_yaml(path: Path) -> Dict[str, object]:
    try:
        raw = path.read_text(encoding="utf-8")
    except FileNotFoundError as exc:  # pragma: no cover - handled by caller
        raise SlashGeneratorError(f"Config file not found: {path}") from exc
    except OSError as exc:  # pragma: no cover - unexpected IO error
        raise SlashGeneratorError(f"Failed to read config file: {path}") from exc

    try:
        data = yaml.safe_load(raw)
    except yaml.YAMLError as exc:
        raise SlashGeneratorError(f"Invalid YAML in {path}: {exc}") from exc

    if not isinstance(data, dict):
        raise SlashGeneratorError("Configuration root must be an object.")
    return data


def load_commands(config_path: Path) -> List[SlashCommand]:
    """Load command definitions from the YAML configuration."""

    data = _read_yaml(config_path)
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
    root = Path(prompt_root).resolve()
    if root not in prompt_path.parents:
        raise SlashGeneratorError(
            f"Prompt file must be inside the prompt directory: {prompt_path}"
        )
    if not prompt_path.is_file():
        raise SlashGeneratorError(f"Prompt file not found: {prompt_path}")
    return prompt_path


def clean_destination(directory: Path) -> None:
    """Ensure the destination directory exists and remove any existing files."""

    directory.mkdir(parents=True, exist_ok=True)
    for path in directory.iterdir():
        if path.is_file() or path.is_symlink():
            path.unlink()


def _render_commands(
    commands: Iterable[SlashCommand],
    *,
    prompt_root: Path,
    destination: Path,
    renderer: Callable[[SlashCommand, str], Tuple[str, str]],
) -> None:
    clean_destination(destination)

    for command in commands:
        prompt_path = ensure_prompt_exists(prompt_root, command.prompt_file)
        prompt_content = prompt_path.read_text(encoding="utf-8")
        relative_name, output_content = renderer(command, prompt_content)

        relative_path = Path(relative_name)
        if relative_path.is_absolute() or ".." in relative_path.parts:
            raise SlashGeneratorError(
                f"Renderer returned invalid output path: {relative_name!r}"
            )

        output_file = destination / relative_path
        output_file.parent.mkdir(parents=True, exist_ok=True)
        output_file.write_text(output_content, encoding="utf-8")


class BaseSlashGenerator(ABC):
    """Base class for slash command generators."""

    _REPO_ANSIBLE_DIR = Path(__file__).resolve().parents[2]
    DEFAULT_CONFIG = _REPO_ANSIBLE_DIR / "roles/slash/config/common/config.yml"
    DEFAULT_PROMPT_ROOT = DEFAULT_CONFIG.parent

    @abstractmethod
    def render(self, command: SlashCommand, prompt_content: str) -> Tuple[str, str]:
        """Render a command to filename and content."""

    @property
    @abstractmethod
    def default_destination(self) -> Path:
        """Default destination directory."""

    def generate(
        self,
        commands: Iterable[SlashCommand],
        *,
        prompt_root: Path,
        destination: Path,
    ) -> None:
        def renderer(cmd: SlashCommand, content: str) -> Tuple[str, str]:
            return self.render(cmd, content)

        _render_commands(
            commands,
            prompt_root=prompt_root,
            destination=destination,
            renderer=renderer,
        )

    @staticmethod
    def parse_args(
        generator_class: type["BaseSlashGenerator"],
        argv: List[str] | None = None,
    ) -> Tuple[Path, Path, Path]:
        import argparse

        parser = argparse.ArgumentParser(description="Generate slash command assets")
        parser.add_argument(
            "--config",
            type=Path,
            default=BaseSlashGenerator.DEFAULT_CONFIG,
            help="Path to config.yml",
        )
        parser.add_argument(
            "--destination",
            type=Path,
            default=None,
            help="Destination directory",
        )
        parser.add_argument(
            "--prompt-root",
            type=Path,
            default=BaseSlashGenerator.DEFAULT_PROMPT_ROOT,
            help="Prompt root directory",
        )
        args = parser.parse_args(argv)
        destination = args.destination or generator_class().default_destination
        return args.config, args.prompt_root, destination

    @staticmethod
    def _escape_yaml_string(value: str) -> str:
        """Escape characters that break simple YAML double-quoted strings."""

        return value.replace("\\", "\\\\").replace('"', '\\"')

    @staticmethod
    def main(generator_class, argv: List[str] | None = None) -> int:
        import sys

        config, prompt_root, destination = BaseSlashGenerator.parse_args(
            generator_class, argv
        )
        try:
            commands = load_commands(config)
            generator = generator_class()
            generator.generate(
                commands,
                prompt_root=prompt_root,
                destination=destination,
            )
        except SlashGeneratorError as exc:
            print(f"Error: {exc}", file=sys.stderr)
            return 1
        return 0
