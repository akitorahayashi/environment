"""Tests for internal SSH command stubs.

Domain behavior is tested in the Rust menv-internal test suite.
These tests verify the Python stubs report missing binary correctly.
"""

from __future__ import annotations

import typer.testing

from menv.commands.internal.ssh import ssh_app

runner = typer.testing.CliRunner()


class TestSshStubs:
    """Verify stub commands report missing binary."""

    def test_gk_reports_missing_binary(self) -> None:
        result = runner.invoke(ssh_app, ["gk", "ed25519", "example.com"])
        assert result.exit_code == 1
        assert "menv-internal binary not found" in result.output

    def test_ls_reports_missing_binary(self) -> None:
        result = runner.invoke(ssh_app, ["ls"])
        assert result.exit_code == 1
        assert "menv-internal binary not found" in result.output

    def test_rm_reports_missing_binary(self) -> None:
        result = runner.invoke(ssh_app, ["rm", "example.com"])
        assert result.exit_code == 1
        assert "menv-internal binary not found" in result.output
