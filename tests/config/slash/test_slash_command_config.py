"""Integrated tests for slash command configuration and assets."""

from __future__ import annotations

import json
import os
import stat
import subprocess
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

    scripts_to_check = ["claude.py", "codex.py", "gemini.py"]

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

    def test_config_is_valid_and_assets_exist(
        self, slash_config_path: Path, slash_config_dir: Path
    ) -> None:
        """Validate configuration file and verify referenced assets exist."""
        # 1. Load and validate configuration file
        try:
            with slash_config_path.open(encoding="utf-8") as f:
                data = json.load(f, object_pairs_hook=self._object_pairs_hook)
        except json.JSONDecodeError as e:
            pytest.fail(f"Invalid JSON in {slash_config_path}: {e}")
        except DuplicateKeyError as e:
            pytest.fail(str(e))

        # 2. Validate schema and check prompt files exist
        self._validate_schema_and_prompts(data, slash_config_dir)

    def test_generator_scripts_are_executable(self, slash_config_dir: Path) -> None:
        """Verify that slash command generator scripts exist and are executable."""
        for script_name in self.scripts_to_check:
            script_path = slash_config_dir / script_name
            assert script_path.is_file(), f"Script not found: {script_path}"
            mode = script_path.stat().st_mode
            assert mode & (
                stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH
            ), f"Script is not executable: {script_path}"

    def test_generators_render_prompts(
        self,
        slash_config_dir: Path,
        project_root: Path,
        tmp_path: Path,
    ) -> None:
        """Run each generator script and ensure outputs are created."""

        env = os.environ.copy()
        env["HOME"] = str(tmp_path)

        config_path = slash_config_dir / "config.json"
        config = json.loads(config_path.read_text(encoding="utf-8"))
        commands = config["commands"]
        first_name, first_spec = next(iter(commands.items()))
        prompt_file = slash_config_dir / first_spec["prompt-file"]
        prompt_content = prompt_file.read_text(encoding="utf-8")

        destinations = {
            "claude.py": tmp_path / ".claude/commands",
            "codex.py": tmp_path / ".codex/prompts",
            "gemini.py": tmp_path / ".gemini/commands",
        }

        for script_name, dest_dir in destinations.items():
            result = subprocess.run(
                [str(slash_config_dir / script_name)],
                cwd=project_root,
                env=env,
                capture_output=True,
                text=True,
            )
            assert (
                result.returncode == 0
            ), f"{script_name} failed with stderr: {result.stderr}"
            assert dest_dir.is_dir(), f"Destination directory missing: {dest_dir}"
            assert any(dest_dir.iterdir()), f"Destination directory empty: {dest_dir}"

        claude_output = (destinations["claude.py"] / f"{first_name}.md").read_text(
            encoding="utf-8"
        )
        assert claude_output.startswith("---\n"), "Claude output missing front matter"
        assert prompt_content.strip() in claude_output

        codex_output = (destinations["codex.py"] / f"{first_name}.md").read_text(
            encoding="utf-8"
        )
        assert codex_output == prompt_content

        gemini_output = (destinations["gemini.py"] / f"{first_name}.toml").read_text(
            encoding="utf-8"
        )
        assert 'prompt = """' in gemini_output
        assert prompt_content.strip() in gemini_output

    def _validate_schema_and_prompts(
        self, data: Dict[str, Any], slash_config_dir: Path
    ) -> None:
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
                assert isinstance(
                    spec[field], str
                ), f"'{field}' in '{name}' must be a string."

            # Verify prompt file exists and is in correct directory
            prompt_file = spec["prompt-file"]
            prompt_path = (slash_config_dir / prompt_file).resolve()
            assert (
                prompt_path.is_file()
            ), f"Prompt file for '{name}' not found: {prompt_file}"
            assert (
                base_resolved in prompt_path.parents
            ), f"Prompt file for '{name}' must be within {slash_config_dir}"
