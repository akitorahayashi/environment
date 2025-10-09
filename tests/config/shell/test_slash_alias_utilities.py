"""Tests for slash alias helper scripts."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

import pytest


def _prepare_commands_dir(tmp_path: Path) -> Path:
    """Create and return a commands directory under a temporary HOME."""
    home_dir = tmp_path / "home"
    commands_dir = home_dir / ".local" / "slash" / "commands"
    commands_dir.mkdir(parents=True)
    return home_dir


class TestGenSlashAliases:
    """Validate alias generation output."""

    def test_generates_aliases_for_prompts(
        self,
        tmp_path: Path,
        monkeypatch: pytest.MonkeyPatch,
        gen_slash_aliases_script_path: Path,
    ) -> None:
        home_dir = _prepare_commands_dir(tmp_path)
        commands_dir = home_dir / ".local" / "slash" / "commands"
        (commands_dir / "cm.md").write_text("/cm prompt", encoding="utf-8")
        (commands_dir / "prm.md").write_text("/prm prompt", encoding="utf-8")

        monkeypatch.setenv("HOME", str(home_dir))
        result = subprocess.run(
            [sys.executable, str(gen_slash_aliases_script_path)],
            capture_output=True,
            text=True,
        )

        assert result.returncode == 0
        lines = [line.strip() for line in result.stdout.splitlines() if line.strip()]
        assert lines == [
            'alias sl-cm="slash_cmd_copier.py cm"',
            'alias sl-prm="slash_cmd_copier.py prm"',
        ]

    def test_no_output_when_directory_missing(
        self,
        tmp_path: Path,
        monkeypatch: pytest.MonkeyPatch,
        gen_slash_aliases_script_path: Path,
    ) -> None:
        monkeypatch.setenv("HOME", str(tmp_path / "empty-home"))
        result = subprocess.run(
            [sys.executable, str(gen_slash_aliases_script_path)],
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0
        assert result.stdout.strip() == ""


class TestSlashCmdCopier:
    """Validate prompt copying script."""

    def test_copies_prompt_to_clipboard(
        self,
        tmp_path: Path,
        monkeypatch: pytest.MonkeyPatch,
        slash_cmd_copier_script_path: Path,
    ) -> None:
        home_dir = _prepare_commands_dir(tmp_path)
        commands_dir = home_dir / ".local" / "slash" / "commands"
        prompt_content = "Use /cm prompt"
        (commands_dir / "cm.md").write_text(prompt_content, encoding="utf-8")

        capture_path = tmp_path / "pbcopy_capture.txt"
        bin_dir = tmp_path / "bin"
        bin_dir.mkdir()
        pbcopy_stub = bin_dir / "pbcopy"
        pbcopy_stub.write_text(
            "#!/usr/bin/env python3\n"
            "import os, sys, pathlib\n"
            "capture = os.environ.get('PB_COPY_CAPTURE_PATH')\n"
            "data = sys.stdin.read()\n"
            "if capture:\n"
            "\tpathlib.Path(capture).write_text(data)\n"
        )
        pbcopy_stub.chmod(0o755)

        env_path = f"{bin_dir}:{os.environ.get('PATH', '')}"
        monkeypatch.setenv("HOME", str(home_dir))
        monkeypatch.setenv("PATH", env_path)
        monkeypatch.setenv("PB_COPY_CAPTURE_PATH", str(capture_path))

        result = subprocess.run(
            [sys.executable, str(slash_cmd_copier_script_path), "cm"],
            capture_output=True,
            text=True,
        )

        assert result.returncode == 0
        assert "✅ Copied prompt for '/cm' to clipboard" in result.stdout
        assert capture_path.read_text(encoding="utf-8") == prompt_content

    def test_missing_prompt_returns_error(
        self,
        tmp_path: Path,
        monkeypatch: pytest.MonkeyPatch,
        slash_cmd_copier_script_path: Path,
    ) -> None:
        home_dir = _prepare_commands_dir(tmp_path)
        commands_dir = home_dir / ".local" / "slash" / "commands"
        commands_dir.mkdir(parents=True, exist_ok=True)

        bin_dir = tmp_path / "bin"
        bin_dir.mkdir()
        pbcopy_stub = bin_dir / "pbcopy"
        pbcopy_stub.write_text("#!/usr/bin/env bash\nexit 0\n")
        pbcopy_stub.chmod(0o755)

        env_path = f"{bin_dir}:{os.environ.get('PATH', '')}"
        monkeypatch.setenv("HOME", str(home_dir))
        monkeypatch.setenv("PATH", env_path)

        result = subprocess.run(
            [sys.executable, str(slash_cmd_copier_script_path), "missing"],
            capture_output=True,
            text=True,
        )

        assert result.returncode == 1
        assert "Prompt file not found for command '/missing'" in result.stderr
        assert result.stdout.strip() == ""
