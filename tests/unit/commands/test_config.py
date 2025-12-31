"""Tests for config command."""

from __future__ import annotations

from typer.testing import CliRunner

from menv.main import app


class TestConfigCommand:
    """Tests for the config command."""

    def test_config_help_shows_subcommands(self, cli_runner: CliRunner) -> None:
        """Test that config --help shows available subcommands."""
        result = cli_runner.invoke(app, ["config", "--help"])

        assert result.exit_code == 0
        # Should show subcommands: set, show, create
        assert "set" in result.output.lower()
        assert "show" in result.output.lower()
        assert "create" in result.output.lower()

    def test_cf_alias_works(self, cli_runner: CliRunner) -> None:
        """Test that 'cf' alias for config works."""
        result = cli_runner.invoke(app, ["cf", "--help"])

        assert result.exit_code == 0
        # Should show same subcommands
        assert "set" in result.output.lower()
        assert "show" in result.output.lower()
        assert "create" in result.output.lower()

    def test_config_no_args_shows_help(self, cli_runner: CliRunner) -> None:
        """Test that config without args shows help."""
        result = cli_runner.invoke(app, ["config"])

        # Should show help or usage info
        assert "set" in result.output.lower() or "Usage" in result.output

    def test_config_show_displays_config_or_error(self, cli_runner: CliRunner) -> None:
        """Test that config show displays config or shows error if not configured."""
        result = cli_runner.invoke(app, ["config", "show"])

        # Either shows config successfully or shows error about no config
        # (depends on whether user has configured menv)
        if result.exit_code == 0:
            assert "personal" in result.output or "work" in result.output
        else:
            assert "No configuration" in result.output or "Error" in result.output

    def test_config_create_help_shows_options(self, cli_runner: CliRunner) -> None:
        """Test that config create --help shows options."""
        result = cli_runner.invoke(app, ["config", "create", "--help"])

        assert result.exit_code == 0
        assert "--overlay" in result.output or "-o" in result.output

    def test_cf_cr_alias_works(self, cli_runner: CliRunner) -> None:
        """Test that 'cf cr' alias for config create works."""
        result = cli_runner.invoke(app, ["cf", "cr", "--help"])

        assert result.exit_code == 0
        assert "--overlay" in result.output or "-o" in result.output

    def test_config_create_invalid_role_shows_error(
        self, cli_runner: CliRunner
    ) -> None:
        """Test that config create with invalid role shows error."""
        result = cli_runner.invoke(app, ["config", "create", "invalid-role-name"])

        assert result.exit_code != 0
        assert "does not have" in result.output or "Error" in result.output
