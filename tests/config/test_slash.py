"""Integrated tests for slash command configuration and assets."""

from __future__ import annotations

import json
import stat
from pathlib import Path
from typing import Any, Dict, List, Sequence, Tuple

import pytest


class DuplicateKeyError(ValueError):
    """Raised when duplicate keys are encountered in a JSON object."""


@pytest.fixture(scope="class")
def slash_config_path(slash_config_dir: Path) -> Path:
    """Path to the slash configuration file."""
    return slash_config_dir / "config.json"


class TestSlashIntegration:
    """Integrated tests for slash command configuration and assets."""

    scripts_to_check = ["claude.sh", "codex.sh", "gemini.sh"]

    @staticmethod
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

    def test_config_is_valid_and_assets_exist(self, slash_config_path: Path, slash_config_dir: Path) -> None:
        """Validate configuration file and verify referenced assets exist."""
        # 1. Load and validate configuration file
        try:
            with slash_config_path.open(encoding="utf-8") as f:
                data = json.load(f, object_pairs_hook=self._object_pairs_hook)
        except json.JSONDecodeError as e:
            assert False, f"Invalid JSON in {slash_config_path}: {e}"
        except Exception as e:  # DuplicateKeyError is caught here
            assert False, str(e)

        # 2. Validate schema and check prompt files exist
        self._validate_schema_and_prompts(data, slash_config_dir)

    def test_generator_scripts_are_executable(self, slash_config_dir: Path) -> None:
        """Verify that slash command generator scripts exist and are executable."""
        for script_name in self.scripts_to_check:
            script_path = slash_config_dir / script_name
            assert script_path.is_file(), f"Script not found: {script_path}"
            mode = script_path.stat().st_mode
            assert (
                mode & (stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
            ), f"Script is not executable: {script_path}"

    def _validate_schema_and_prompts(self, data: Dict[str, Any], slash_config_dir: Path) -> None:
        """Validate configuration schema and verify prompt files exist."""
        assert "commands" in data, "Top-level 'commands' object is missing."
        commands = data["commands"]
        assert isinstance(commands, dict), "'commands' must be an object."

        required_fields: Sequence[str] = ("title", "description", "prompt-file")
        base_resolved = slash_config_dir.resolve()

        for name, spec in commands.items():
            assert isinstance(spec, dict), f"Command '{name}' must be an object."

            for field in required_fields:
                assert field in spec, f"Command '{name}' is missing '{field}'."
                assert isinstance(spec[field], str), f"'{field}' in '{name}' must be a string."

            # Verify prompt file exists and is in correct directory
            prompt_file = spec["prompt-file"]
            prompt_path = (slash_config_dir / prompt_file).resolve()
            assert prompt_path.is_file(), f"Prompt file for '{name}' not found: {prompt_file}"
            assert (
                base_resolved in prompt_path.parents
            ), f"Prompt file for '{name}' must be within {slash_config_dir}"