"""Tests for internal shell helper commands."""

from __future__ import annotations

import json
from pathlib import Path

import typer.testing

from menv.commands.internal.shell import shell_app

runner = typer.testing.CliRunner()


class TestGenGeminiAliases:
    """Tests for gen-gemini-aliases command."""

    def test_output_contains_expected_aliases(self) -> None:
        result = runner.invoke(shell_app, ["gen-gemini-aliases"])
        assert result.exit_code == 0
        lines = result.output.strip().split("\n")

        assert 'alias gm-pr="gemini -m gemini-3-pro-preview"' in lines
        assert 'alias gm-fl="gemini -m gemini-3-flash-preview"' in lines
        assert 'alias gm-pr-y="gemini -m gemini-3-pro-preview -y"' in lines
        assert 'alias gm-fl-ap="gemini -m gemini-3-flash-preview -a -p"' in lines

        # 5 models × 6 options = 30 aliases
        assert len(lines) == 30
        assert all(line.startswith("alias ") for line in lines)


class TestGenVscodeWorkspace:
    """Tests for gen-vscode-workspace command."""

    def test_creates_workspace_file(self, tmp_path: Path, monkeypatch) -> None:
        monkeypatch.chdir(tmp_path)
        result = runner.invoke(
            shell_app, ["gen-vscode-workspace", "../path1", "/abs/path2"]
        )
        assert result.exit_code == 0
        assert "Workspace file created" in result.output

        ws_file = tmp_path / "workspace.code-workspace"
        assert ws_file.exists()
        content = json.loads(ws_file.read_text())
        assert content == {"folders": [{"path": "../path1"}, {"path": "/abs/path2"}]}

    def test_requires_at_least_one_path(self) -> None:
        result = runner.invoke(shell_app, ["gen-vscode-workspace"])
        assert result.exit_code != 0
