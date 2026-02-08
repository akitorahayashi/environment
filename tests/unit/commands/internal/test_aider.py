"""Tests for internal Aider commands."""

from __future__ import annotations

import os
from unittest.mock import MagicMock, patch

import typer.testing

from menv.commands.internal.aider import aider_app

runner = typer.testing.CliRunner()


class TestSetModel:
    """Tests for aider set-model command."""

    def test_emits_export(self) -> None:
        result = runner.invoke(aider_app, ["set-model", "llama3.2"])
        assert result.exit_code == 0
        assert "export AIDER_OLLAMA_MODEL=llama3.2" in result.output
        assert "echo '✅ Set AIDER_OLLAMA_MODEL to: 'llama3.2" in result.output

    def test_no_arg_shows_usage(self) -> None:
        with patch.dict(os.environ, {"AIDER_OLLAMA_MODEL": "existing"}):
            result = runner.invoke(aider_app, ["set-model"])
        assert result.exit_code == 1
        assert "Usage: set-model <model_name>" in result.stderr
        assert "Current AIDER_OLLAMA_MODEL: existing" in result.stderr


class TestUnsetModel:
    """Tests for aider unset-model command."""

    def test_emits_unset(self) -> None:
        with patch.dict(os.environ, {"AIDER_OLLAMA_MODEL": "llama3.2"}):
            result = runner.invoke(aider_app, ["unset-model"])
        assert result.exit_code == 0
        assert "unset AIDER_OLLAMA_MODEL" in result.output
        assert 'echo "✅ Unset AIDER_OLLAMA_MODEL"' in result.output

    def test_already_unset(self) -> None:
        env = os.environ.copy()
        env.pop("AIDER_OLLAMA_MODEL", None)
        with patch.dict(os.environ, env, clear=True):
            result = runner.invoke(aider_app, ["unset-model"])
        assert result.exit_code == 0
        assert "already not set" in result.output


class TestListModels:
    """Tests for aider list-models command."""

    @patch("menv.commands.internal.aider.subprocess.run")
    @patch("menv.commands.internal.aider.shutil.which", return_value="/usr/bin/ollama")
    def test_lists_models(self, mock_which, mock_run) -> None:
        mock_run.return_value = MagicMock(
            stdout="NAME\nllama3.2\nqwen2.5\n", returncode=0
        )
        result = runner.invoke(aider_app, ["list-models"])
        assert result.exit_code == 0
        assert "llama3.2" in result.output
        assert "qwen2.5" in result.output
        assert "Available Ollama models for aider:" in result.output

    @patch("menv.commands.internal.aider.shutil.which", return_value=None)
    def test_no_ollama(self, mock_which) -> None:
        result = runner.invoke(aider_app, ["list-models"])
        assert result.exit_code == 1
        assert "Ollama is not installed" in result.stderr


class TestRun:
    """Tests for aider run command."""

    def test_fails_without_model_env(self) -> None:
        env = os.environ.copy()
        env.pop("AIDER_OLLAMA_MODEL", None)
        with patch.dict(os.environ, env, clear=True):
            result = runner.invoke(aider_app, ["run"])
        assert result.exit_code == 1
        assert "AIDER_OLLAMA_MODEL" in result.stderr

    @patch("menv.commands.internal.aider.subprocess.run")
    def test_invokes_aider_with_model(self, mock_run) -> None:
        mock_run.return_value = MagicMock(returncode=0)
        with patch.dict(os.environ, {"AIDER_OLLAMA_MODEL": "mini"}):
            result = runner.invoke(aider_app, ["run"])
        assert result.exit_code == 0
        cmd = mock_run.call_args.args[0]
        assert cmd == [
            "aider",
            "--model",
            "ollama/mini",
            "--no-auto-commit",
            "--no-gitignore",
        ]

    @patch("menv.commands.internal.aider.subprocess.run")
    def test_passes_yes_flag(self, mock_run) -> None:
        mock_run.return_value = MagicMock(returncode=0)
        with patch.dict(os.environ, {"AIDER_OLLAMA_MODEL": "mini"}):
            runner.invoke(aider_app, ["run", "-y"])
        cmd = mock_run.call_args.args[0]
        assert "--yes" in cmd

    @patch("menv.commands.internal.aider.subprocess.run")
    def test_preserves_provider_slash_model(self, mock_run) -> None:
        mock_run.return_value = MagicMock(returncode=0)
        with patch.dict(os.environ, {"AIDER_OLLAMA_MODEL": "provider/model"}):
            runner.invoke(aider_app, ["run"])
        cmd = mock_run.call_args.args[0]
        assert "provider/model" in cmd
        assert "ollama/provider/model" not in cmd
