"""Integrated tests for slash command configuration and assets."""

from __future__ import annotations

import json
import stat
import unittest
from pathlib import Path
from typing import Any, Dict, List, Sequence, Tuple


class DuplicateKeyError(ValueError):
    """Raised when duplicate keys are encountered in a JSON object."""


class SlashIntegrationTests(unittest.TestCase):
    """Integrated tests for slash command configuration and assets."""

    def setUp(self) -> None:
        """Set up test fixtures."""
        self.config_path = Path("config/common/slash/config.json")
        self.base_dir = self.config_path.parent
        self.scripts_to_check = ["claude.sh", "codex.sh", "gemini.sh"]

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

    def test_config_is_valid_and_assets_exist(self) -> None:
        """Validate configuration file and verify referenced assets exist."""
        # 1. Load and validate configuration file
        try:
            with self.config_path.open(encoding="utf-8") as f:
                data = json.load(f, object_pairs_hook=self._object_pairs_hook)
        except json.JSONDecodeError as e:
            self.fail(f"Invalid JSON in {self.config_path}: {e}")
        except Exception as e:  # DuplicateKeyError is caught here
            self.fail(str(e))

        # 2. Validate schema and check prompt files exist
        self._validate_schema_and_prompts(data)

    def test_generator_scripts_are_executable(self) -> None:
        """Verify that slash command generator scripts exist and are executable."""
        for script_name in self.scripts_to_check:
            script_path = self.base_dir / script_name
            with self.subTest(script=script_name):
                self.assertTrue(script_path.is_file(), f"Script not found: {script_path}")
                mode = script_path.stat().st_mode
                self.assertTrue(
                    mode & (stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH),
                    f"Script is not executable: {script_path}",
                )

    def _validate_schema_and_prompts(self, data: Dict[str, Any]) -> None:
        """Validate configuration schema and verify prompt files exist."""
        self.assertIn("commands", data, "Top-level 'commands' object is missing.")
        commands = data["commands"]
        self.assertIsInstance(commands, dict, "'commands' must be an object.")

        required_fields: Sequence[str] = ("title", "description", "prompt-file")
        base_resolved = self.base_dir.resolve()

        for name, spec in commands.items():
            with self.subTest(command=name):
                self.assertIsInstance(spec, dict, f"Command '{name}' must be an object.")

                for field in required_fields:
                    self.assertIn(field, spec, f"Command '{name}' is missing '{field}'.")
                    self.assertIsInstance(spec[field], str, f"'{field}' in '{name}' must be a string.")

                # Verify prompt file exists and is in correct directory
                prompt_file = spec["prompt-file"]
                prompt_path = (self.base_dir / prompt_file).resolve()
                self.assertTrue(prompt_path.is_file(), f"Prompt file for '{name}' not found: {prompt_file}")
                self.assertIn(
                    base_resolved,
                    prompt_path.parents,
                    f"Prompt file for '{name}' must be within {self.base_dir}",
                )


if __name__ == "__main__":
    unittest.main()