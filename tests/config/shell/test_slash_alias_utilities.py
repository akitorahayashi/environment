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


@pytest.fixture
def mock_clipboard(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    """Set up a mock clipboard command and environment."""
    capture_path = tmp_path / "clipboard_capture.txt"
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    pbcopy_stub = bin_dir / "pbcopy"
    pbcopy_stub.write_text(
        "#!/usr/bin/env python3\n"
        "import os, sys, pathlib\n"
        "capture = os.environ.get('PB_COPY_CAPTURE_PATH')\n"
        "data = sys.stdin.read()\n"
        "if capture:\n"
        "    pathlib.Path(capture).write_text(data)\n"
    )
    pbcopy_stub.chmod(0o755)

    env_path = f"{bin_dir}:{os.environ.get('PATH', '')}"
    monkeypatch.setenv("PATH", env_path)
    monkeypatch.setenv("PB_COPY_CAPTURE_PATH", str(capture_path))

    return capture_path


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
        nested_dir = commands_dir / "async-sdd-slashes"
        nested_dir.mkdir()
        (nested_dir / "sdd-3-tk.md").write_text(
            "/async-sdd-slashes/sdd-3-tk prompt",
            encoding="utf-8",
        )

        monkeypatch.setenv("HOME", str(home_dir))
        result = subprocess.run(
            [sys.executable, str(gen_slash_aliases_script_path)],
            capture_output=True,
            text=True,
        )

        assert result.returncode == 0
        lines = [line.strip() for line in result.stdout.splitlines() if line.strip()]
        assert lines == [
            'alias sl-async-sdd-slashes-sdd-3-tk="slash_cmd_copier.py async-sdd-slashes/sdd-3-tk"',
            'alias sl-cm="slash_cmd_copier.py cm"',
            'alias sl-prm="slash_cmd_copier.py prm"',
            'alias sl-sdd-3-tk="slash_cmd_copier.py async-sdd-slashes/sdd-3-tk"',
        ]

    def test_short_alias_not_generated_when_duplicate_basename(
        self,
        tmp_path: Path,
        monkeypatch: pytest.MonkeyPatch,
        gen_slash_aliases_script_path: Path,
    ) -> None:
        home_dir = _prepare_commands_dir(tmp_path)
        commands_dir = home_dir / ".local" / "slash" / "commands"
        nested_a = commands_dir / "alpha"
        nested_b = commands_dir / "beta"
        nested_a.mkdir()
        nested_b.mkdir()
        (nested_a / "shared.md").write_text("/alpha/shared", encoding="utf-8")
        (nested_b / "shared.md").write_text("/beta/shared", encoding="utf-8")

        monkeypatch.setenv("HOME", str(home_dir))
        result = subprocess.run(
            [sys.executable, str(gen_slash_aliases_script_path)],
            capture_output=True,
            text=True,
        )

        assert result.returncode == 0
        lines = [line.strip() for line in result.stdout.splitlines() if line.strip()]
        assert 'alias sl-shared="slash_cmd_copier.py alpha/shared"' not in lines
        assert 'alias sl-alpha-shared="slash_cmd_copier.py alpha/shared"' in lines
        assert 'alias sl-beta-shared="slash_cmd_copier.py beta/shared"' in lines

    def test_list_formatting(
        self,
        tmp_path: Path,
        monkeypatch: pytest.MonkeyPatch,
        gen_slash_aliases_script_path: Path,
    ) -> None:
        home_dir = _prepare_commands_dir(tmp_path)
        commands_dir = home_dir / ".local" / "slash" / "commands"
        (commands_dir / "cm.md").write_text("/cm prompt", encoding="utf-8")
        nested_dir = commands_dir / "async-sdd-slashes"
        nested_dir.mkdir()
        (nested_dir / "sdd-3-tk.md").write_text("/nested", encoding="utf-8")

        monkeypatch.setenv("HOME", str(home_dir))
        result = subprocess.run(
            [sys.executable, str(gen_slash_aliases_script_path), "--list"],
            capture_output=True,
            text=True,
        )

        assert result.returncode == 0
        lines = [
            line.rstrip("\n") for line in result.stdout.splitlines() if line.strip()
        ]
        parsed = [tuple(line.split(maxsplit=1)) for line in lines]
        assert parsed == [
            ("sl-async-sdd-slashes-sdd-3-tk", "/async-sdd-slashes/sdd-3-tk"),
            ("sl-cm", "/cm"),
            ("sl-sdd-3-tk", "/async-sdd-slashes/sdd-3-tk"),
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

    def test_excludes_documentation_files(
        self,
        tmp_path: Path,
        monkeypatch: pytest.MonkeyPatch,
        gen_slash_aliases_script_path: Path,
    ) -> None:
        home_dir = _prepare_commands_dir(tmp_path)
        commands_dir = home_dir / ".local" / "slash" / "commands"
        (commands_dir / "cm.md").write_text("/cm prompt", encoding="utf-8")
        (commands_dir / "README.md").write_text("Documentation", encoding="utf-8")
        (commands_dir / "AGENTS.md").write_text("Agent docs", encoding="utf-8")
        (commands_dir / "CLAUDE.md").write_text("Claude docs", encoding="utf-8")
        (commands_dir / "GEMINI.md").write_text("Gemini docs", encoding="utf-8")

        monkeypatch.setenv("HOME", str(home_dir))
        result = subprocess.run(
            [sys.executable, str(gen_slash_aliases_script_path)],
            capture_output=True,
            text=True,
        )

        assert result.returncode == 0
        lines = [line.strip() for line in result.stdout.splitlines() if line.strip()]
        # Should only have the cm alias, not the documentation files
        assert lines == ['alias sl-cm="slash_cmd_copier.py cm"']

    def test_excludes_documentation_files_in_list(
        self,
        tmp_path: Path,
        monkeypatch: pytest.MonkeyPatch,
        gen_slash_aliases_script_path: Path,
    ) -> None:
        home_dir = _prepare_commands_dir(tmp_path)
        commands_dir = home_dir / ".local" / "slash" / "commands"
        (commands_dir / "cm.md").write_text("/cm prompt", encoding="utf-8")
        (commands_dir / "README.md").write_text("Documentation", encoding="utf-8")
        nested_dir = commands_dir / "docs"
        nested_dir.mkdir()
        (nested_dir / "AGENTS.md").write_text("Agent docs", encoding="utf-8")

        monkeypatch.setenv("HOME", str(home_dir))
        result = subprocess.run(
            [sys.executable, str(gen_slash_aliases_script_path), "--list"],
            capture_output=True,
            text=True,
        )

        assert result.returncode == 0
        lines = [
            line.rstrip("\n") for line in result.stdout.splitlines() if line.strip()
        ]
        parsed = [tuple(line.split(maxsplit=1)) for line in lines]
        # Should only have the cm alias, not the documentation files
        assert parsed == [("sl-cm", "/cm")]


class TestSlashCmdCopier:
    """Validate prompt copying script."""

    def test_copies_prompt_to_clipboard(
        self,
        tmp_path: Path,
        monkeypatch: pytest.MonkeyPatch,
        slash_cmd_copier_script_path: Path,
        mock_clipboard: Path,
    ) -> None:
        home_dir = _prepare_commands_dir(tmp_path)
        commands_dir = home_dir / ".local" / "slash" / "commands"
        prompt_content = "Use /cm prompt"
        (commands_dir / "cm.md").write_text(prompt_content, encoding="utf-8")

        capture_path = mock_clipboard
        monkeypatch.setenv("HOME", str(home_dir))

        result = subprocess.run(
            [sys.executable, str(slash_cmd_copier_script_path), "cm"],
            capture_output=True,
            text=True,
        )

        assert result.returncode == 0
        assert "✅ Copied prompt for '/cm' to clipboard" in result.stdout
        assert capture_path.read_text(encoding="utf-8") == prompt_content

    def test_copies_prompt_from_nested_directory(
        self,
        tmp_path: Path,
        monkeypatch: pytest.MonkeyPatch,
        slash_cmd_copier_script_path: Path,
        mock_clipboard: Path,
    ) -> None:
        home_dir = _prepare_commands_dir(tmp_path)
        commands_dir = home_dir / ".local" / "slash" / "commands"
        nested_dir = commands_dir / "async-sdd-slashes"
        nested_dir.mkdir()
        prompt_content = "Use /async-sdd-slashes/sdd-3-tk prompt"
        (nested_dir / "sdd-3-tk.md").write_text(prompt_content, encoding="utf-8")

        capture_path = mock_clipboard
        monkeypatch.setenv("HOME", str(home_dir))

        result = subprocess.run(
            [
                sys.executable,
                str(slash_cmd_copier_script_path),
                "async-sdd-slashes/sdd-3-tk",
            ],
            capture_output=True,
            text=True,
        )

        assert result.returncode == 0
        assert (
            "✅ Copied prompt for '/async-sdd-slashes/sdd-3-tk' to clipboard"
            in result.stdout
        )
        assert capture_path.read_text(encoding="utf-8") == prompt_content

    def test_missing_prompt_returns_error(
        self,
        tmp_path: Path,
        monkeypatch: pytest.MonkeyPatch,
        slash_cmd_copier_script_path: Path,
    ) -> None:
        home_dir = _prepare_commands_dir(tmp_path)

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
