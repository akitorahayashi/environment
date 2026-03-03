"""Tests for internal command visibility from the main app."""

from __future__ import annotations

from typer.testing import CliRunner

from menv.commands.internal.app import internal_app

runner = CliRunner()


class TestInternalAppRouting:
    """Verify that internal_app routes to sub-commands."""

    def test_no_args_shows_help(self) -> None:
        result = runner.invoke(internal_app, [])
        assert result.exit_code in (0, 2)
        assert "Usage:" in result.output
        assert "internal" in result.output.lower()

    def test_unknown_subcommand_fails(self) -> None:
        result = runner.invoke(internal_app, ["nonexistent"])
        assert result.exit_code != 0
        assert "No such command" in result.output
