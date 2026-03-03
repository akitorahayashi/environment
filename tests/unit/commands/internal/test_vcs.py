"""Tests for internal VCS command stubs.

Domain behavior is tested in the Rust menv-internal test suite.
These tests verify the Python stubs report missing binary correctly.
"""

from __future__ import annotations

import typer.testing

from menv.commands.internal.vcs import vcs_app

runner = typer.testing.CliRunner()


class TestVcsStubs:
    """Verify stub commands report missing binary."""

    def test_delete_submodule_reports_missing_binary(self) -> None:
        result = runner.invoke(vcs_app, ["libs/foo"])
        assert result.exit_code == 1
        assert "menv-internal binary not found" in result.output
