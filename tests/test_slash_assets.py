#!/usr/bin/env python3
"""Regression tests for relocated slash configuration assets."""

from __future__ import annotations

import json
import stat
import unittest
from pathlib import Path
from typing import Dict

from tests.test_slash_config import (  # type: ignore
    CONFIG_PATH,
    DuplicateKeyError,
    _object_pairs_hook,
)


class SlashAssetTests(unittest.TestCase):
    """Ensure relocated slash assets remain available and executable."""

    def setUp(self) -> None:
        self.base_dir = CONFIG_PATH.parent

    def test_scripts_exist_and_are_executable(self) -> None:
        """Key slash generators must exist under the new directory and be executable."""
        script_names = ("claude.sh", "codex.sh", "gemini.sh")
        for name in script_names:
            script_path = self.base_dir / name
            with self.subTest(script=name):
                self.assertTrue(script_path.is_file(), f"Missing script: {script_path}")
                mode = script_path.stat().st_mode
                self.assertTrue(
                    mode & (stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH),
                    f"Script is not executable: {script_path}",
                )

    def test_command_prompts_resolve_within_directory(self) -> None:
        """All prompt files referenced in config must exist within the relocated directory."""
        commands = self._load_commands()
        for name, spec in commands.items():
            prompt_file = spec.get("prompt-file")
            with self.subTest(command=name):
                self.assertIsInstance(prompt_file, str, "prompt-file must be a string")
                prompt_path = (self.base_dir / prompt_file).resolve()
                self.assertTrue(
                    prompt_path.is_file(),
                    f"Prompt file not found for {name}: {prompt_file}",
                )
                self.assertTrue(
                    self.base_dir.resolve() in prompt_path.parents
                    or prompt_path == self.base_dir.resolve(),
                    "Prompt file must reside within the slash directory",
                )

    def _load_commands(self) -> Dict[str, Dict[str, object]]:
        with CONFIG_PATH.open(encoding="utf-8") as handle:
            try:
                data = json.load(handle, object_pairs_hook=_object_pairs_hook)
            except (json.JSONDecodeError, DuplicateKeyError) as exc:
                raise AssertionError(f"Failed to load slash config: {exc}") from exc
        commands = data.get("commands")
        self.assertIsInstance(commands, dict, "commands section missing or invalid")
        return commands  # type: ignore[return-value]


if __name__ == "__main__":
    unittest.main()
