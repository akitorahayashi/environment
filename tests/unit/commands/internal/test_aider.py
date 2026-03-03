"""Tests for internal aider command stubs.

Domain behavior is tested in the Rust menv-internal test suite.
These tests verify the Python stubs report missing binary correctly.
"""

from __future__ import annotations

import typer.testing

from menv.commands.internal.aider import aider_app

runner = typer.testing.CliRunner()


class TestAiderStubs:
    """Verify stub commands report missing binary."""

    def test_run_reports_missing_binary(self) -> None:
        result = runner.invoke(aider_app, ["run"])
        assert result.exit_code == 1
        assert "menv-internal binary not found" in result.output

    def test_set_model_reports_missing_binary(self) -> None:
        result = runner.invoke(aider_app, ["set-model", "test"])
        assert result.exit_code == 1
        assert "menv-internal binary not found" in result.output

    def test_unset_model_reports_missing_binary(self) -> None:
        result = runner.invoke(aider_app, ["unset-model"])
        assert result.exit_code == 1
        assert "menv-internal binary not found" in result.output

    def test_list_models_reports_missing_binary(self) -> None:
        result = runner.invoke(aider_app, ["list-models"])
        assert result.exit_code == 1
        assert "menv-internal binary not found" in result.output
