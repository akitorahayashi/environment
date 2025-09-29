#!/usr/bin/env python3
"""Validate slash command configuration integrity.

Checks performed:
- JSON syntax correctness
- Duplicate keys in any object
- Presence and types of required fields per command
- Existence of referenced prompt files within the slash commands directory
"""

from __future__ import annotations

import json
import unittest
from pathlib import Path
from typing import Any, Dict, List, Sequence, Tuple

CONFIG_PATH = Path("config/common/slash/config.json")


class DuplicateKeyError(ValueError):
    """Raised when duplicate keys are encountered in a JSON object."""


def _object_pairs_hook(pairs: List[Tuple[str, Any]]) -> Dict[str, Any]:
    """Hook for json.load to track duplicate keys while preserving parsing semantics."""
    result: Dict[str, Any] = {}
    duplicates: List[str] = []

    for key, value in pairs:
        if key in result:
            duplicates.append(key)
        result[key] = value

    if duplicates:
        raise DuplicateKeyError(
            "Duplicate keys detected: " + ", ".join(sorted(set(duplicates)))
        )

    return result


def validate_config(path: Path = CONFIG_PATH) -> None:
    """Validate the configuration file for syntax errors, duplicates, and schema compliance."""
    if not path.is_file():
        raise FileNotFoundError(f"Configuration file not found: {path}")

    with path.open(encoding="utf-8") as handle:
        try:
            data = json.load(handle, object_pairs_hook=_object_pairs_hook)
        except json.JSONDecodeError as exc:
            raise ValueError(f"Invalid JSON syntax in {path}: {exc}") from exc
        except DuplicateKeyError as exc:
            raise ValueError(f"{exc}") from exc

    _validate_schema(data, base_dir=path.parent)


def _validate_schema(data: Any, *, base_dir: Path) -> None:
    if not isinstance(data, dict):
        raise ValueError("Root JSON structure must be an object.")

    if "commands" not in data:
        raise ValueError("Missing top-level 'commands' object.")

    commands = data["commands"]
    if not isinstance(commands, dict):
        raise ValueError("'commands' must be a JSON object mapping command names to configs.")

    try:
        base_resolved = base_dir.resolve()
    except FileNotFoundError:
        base_resolved = base_dir

    required_fields: Sequence[str] = ("title", "description", "prompt-file")
    errors: List[str] = []

    for name, spec in commands.items():
        if not isinstance(spec, dict):
            errors.append(f"Command '{name}' must be a JSON object.")
            continue

        missing = [field for field in required_fields if field not in spec]
        if missing:
            errors.append(
                f"Command '{name}' is missing required field(s): {', '.join(missing)}"
            )

        for field in required_fields:
            if field in spec and not isinstance(spec[field], str):
                errors.append(f"Command '{name}' field '{field}' must be a string.")

        prompt_file = spec.get("prompt-file")
        if isinstance(prompt_file, str):
            prompt_path = (base_dir / prompt_file).resolve()
            if base_resolved not in prompt_path.parents and prompt_path != base_resolved:
                errors.append(
                    f"Command '{name}' prompt-file '{prompt_file}' must reside within {base_dir}"
                )
            elif not prompt_path.is_file():
                errors.append(
                    f"Command '{name}' prompt-file '{prompt_file}' does not exist."
                )

    if errors:
        raise ValueError("; ".join(errors))


class SlashConfigTests(unittest.TestCase):
    """Unit tests ensuring the slash command configuration remains valid."""

    def test_config_is_valid(self) -> None:
        """Validate the shared slash command configuration."""
        validate_config()


if __name__ == "__main__":
    unittest.main()
